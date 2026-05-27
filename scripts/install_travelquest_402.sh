#!/bin/bash
set -euo pipefail

: "${MONGO_HOSTS:?MONGO_HOSTS is required}"
: "${MONGO_APP_USERNAME:?MONGO_APP_USERNAME is required}"
: "${MONGO_APP_PASSWORD:?MONGO_APP_PASSWORD is required}"
: "${TRAVELQUEST_API_TOKEN:?TRAVELQUEST_API_TOKEN is required}"

install -d -m 0755 /var/www/html/402 /var/www/html/api/402

cat > /var/www/html/api/402/config.php <<EOF
<?php
return [
    'mongo_hosts' => '${MONGO_HOSTS}',
    'mongo_user' => '${MONGO_APP_USERNAME}',
    'mongo_password' => '${MONGO_APP_PASSWORD}',
    'api_token' => '${TRAVELQUEST_API_TOKEN}',
];
EOF

cat > /var/www/html/api/402/bootstrap.php <<'PHP'
<?php
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

require_once '/var/www/html/vendor/autoload.php';

function tq_config(): array {
    static $config = null;
    if ($config === null) {
        $config = require __DIR__ . '/config.php';
    }
    return $config;
}

function tq_headers(): void {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Content-Type,Authorization,X-Api-Key');
    header('Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS');
    header('Content-Type: application/json');
    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}

function tq_json(int $status, array $payload): void {
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_SLASHES);
    exit;
}

function tq_request_header(string $name): string {
    $serverKey = 'HTTP_' . strtoupper(str_replace('-', '_', $name));
    if (isset($_SERVER[$serverKey])) {
        return (string)$_SERVER[$serverKey];
    }
    if (function_exists('apache_request_headers')) {
        foreach (apache_request_headers() as $header => $value) {
            if (strcasecmp($header, $name) === 0) {
                return (string)$value;
            }
        }
    }
    return '';
}

function tq_require_auth(): void {
    $config = tq_config();
    $expected = (string)($config['api_token'] ?? '');
    $provided = '';
    $authHeader = tq_request_header('Authorization');

    if (preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
        $provided = trim($matches[1]);
    }

    if ($provided === '') {
        $provided = trim(tq_request_header('X-Api-Key'));
    }

    if ($expected === '' || $provided === '' || !hash_equals($expected, $provided)) {
        tq_json(401, [
            'message' => 'Authentication required',
            'required_header' => 'Authorization: Bearer <token>'
        ]);
    }
}

function tq_db(): MongoDB\Database {
    $config = tq_config();
    $uri = 'mongodb://' . rawurlencode($config['mongo_user']) . ':' . rawurlencode($config['mongo_password']) .
        '@' . $config['mongo_hosts'] . '/civicnexus?authSource=civicnexus&replicaSet=rs0';

    $client = new MongoDB\Client($uri, [], [
        'serverSelectionTimeoutMS' => 2000,
        'connectTimeoutMS' => 2000
    ]);

    return $client->selectDatabase('civicnexus');
}

function tq_body(): array {
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    $body = json_decode($raw, true);
    if (!is_array($body)) {
        tq_json(400, ['message' => 'Request body must be valid JSON']);
    }
    return $body;
}

function tq_text(array $body, string $field, string $default = ''): string {
    $value = trim((string)($body[$field] ?? $default));
    return substr($value, 0, 500);
}

function tq_id(): string {
    return bin2hex(random_bytes(8));
}

function tq_destination($doc): array {
    return [
        'id' => (string)($doc['id'] ?? ''),
        'name' => (string)($doc['name'] ?? ''),
        'location' => (string)($doc['location'] ?? ''),
        'description' => (string)($doc['description'] ?? ''),
        'imageUrl' => (string)($doc['imageUrl'] ?? ''),
        'createdAt' => (int)($doc['createdAt'] ?? 0)
    ];
}

function tq_comment($doc): array {
    return [
        'commentId' => (string)($doc['commentId'] ?? ''),
        'destinationId' => (string)($doc['destinationId'] ?? ''),
        'author' => (string)($doc['author'] ?? 'Visitor'),
        'text' => (string)($doc['text'] ?? ''),
        'timestamp' => (int)($doc['timestamp'] ?? 0)
    ];
}
PHP

cat > /var/www/html/api/402/health.php <<'PHP'
<?php
require_once __DIR__ . '/bootstrap.php';
tq_headers();
tq_require_auth();

try {
    $db = tq_db();
    $db->command(['ping' => 1]);
    tq_json(200, [
        'service' => 'travelquest-402-api',
        'status' => 'ok',
        'database' => 'reachable',
        'destinations' => $db->travelquest_destinations->countDocuments(),
        'comments' => $db->travelquest_comments->countDocuments()
    ]);
} catch (Exception $e) {
    error_log('TravelQuest API health error: ' . $e->getMessage());
    tq_json(503, [
        'service' => 'travelquest-402-api',
        'status' => 'degraded',
        'database' => 'unreachable'
    ]);
}
PHP

cat > /var/www/html/api/402/destinations.php <<'PHP'
<?php
require_once __DIR__ . '/bootstrap.php';
tq_headers();
tq_require_auth();

try {
    $db = tq_db();
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    $id = trim((string)($_GET['id'] ?? ''));

    if ($method === 'GET') {
        if ($id !== '') {
            $doc = $db->travelquest_destinations->findOne(['id' => $id]);
            if (!$doc) {
                tq_json(404, ['message' => 'Destination not found']);
            }
            tq_json(200, tq_destination($doc));
        }

        $items = [];
        foreach ($db->travelquest_destinations->find([], ['sort' => ['createdAt' => -1]]) as $doc) {
            $items[] = tq_destination($doc);
        }
        tq_json(200, ['items' => $items]);
    }

    if ($method === 'POST') {
        $body = tq_body();
        $name = tq_text($body, 'name');
        if ($name === '') {
            tq_json(400, ['message' => 'Destination name is required']);
        }

        $item = [
            'id' => tq_id(),
            'name' => $name,
            'location' => tq_text($body, 'location', 'Australia'),
            'description' => tq_text($body, 'description'),
            'imageUrl' => tq_text($body, 'imageUrl', 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=1200&q=80'),
            'createdAt' => (int)round(microtime(true) * 1000)
        ];
        $db->travelquest_destinations->insertOne($item);
        tq_json(201, $item);
    }

    if ($method === 'PUT') {
        if ($id === '') {
            tq_json(400, ['message' => 'Destination id is required']);
        }
        $body = tq_body();
        $set = [];
        foreach (['name', 'location', 'description', 'imageUrl'] as $field) {
            if (array_key_exists($field, $body)) {
                $set[$field] = tq_text($body, $field);
            }
        }
        if (!$set) {
            tq_json(400, ['message' => 'No updatable fields provided']);
        }
        $result = $db->travelquest_destinations->updateOne(['id' => $id], ['$set' => $set]);
        tq_json(200, [
            'matched' => $result->getMatchedCount(),
            'modified' => $result->getModifiedCount()
        ]);
    }

    if ($method === 'DELETE') {
        if ($id === '') {
            tq_json(400, ['message' => 'Destination id is required']);
        }
        $deleted = $db->travelquest_destinations->deleteOne(['id' => $id])->getDeletedCount();
        $db->travelquest_comments->deleteMany(['destinationId' => $id]);
        tq_json(200, ['deleted' => $deleted]);
    }

    tq_json(405, ['message' => 'Method not allowed']);
} catch (Exception $e) {
    error_log('TravelQuest destinations API error: ' . $e->getMessage());
    tq_json(500, ['message' => 'TravelQuest API error']);
}
PHP

cat > /var/www/html/api/402/comments.php <<'PHP'
<?php
require_once __DIR__ . '/bootstrap.php';
tq_headers();
tq_require_auth();

try {
    $db = tq_db();
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    $destinationId = trim((string)($_GET['destinationId'] ?? ''));
    $commentId = trim((string)($_GET['commentId'] ?? ''));

    if ($destinationId === '') {
        tq_json(400, ['message' => 'destinationId is required']);
    }

    if ($method === 'GET') {
        $items = [];
        foreach ($db->travelquest_comments->find(['destinationId' => $destinationId], ['sort' => ['timestamp' => 1]]) as $doc) {
            $items[] = tq_comment($doc);
        }
        tq_json(200, ['items' => $items]);
    }

    if ($method === 'POST') {
        $body = tq_body();
        $text = tq_text($body, 'text');
        if ($text === '') {
            tq_json(400, ['message' => 'Comment text is required']);
        }

        $item = [
            'commentId' => tq_id(),
            'destinationId' => $destinationId,
            'author' => tq_text($body, 'author', 'Visitor'),
            'text' => $text,
            'timestamp' => (int)round(microtime(true) * 1000)
        ];
        $db->travelquest_comments->insertOne($item);
        tq_json(201, $item);
    }

    if ($method === 'DELETE') {
        if ($commentId === '') {
            tq_json(400, ['message' => 'commentId is required']);
        }
        $deleted = $db->travelquest_comments->deleteOne([
            'destinationId' => $destinationId,
            'commentId' => $commentId
        ])->getDeletedCount();
        tq_json(200, ['deleted' => $deleted]);
    }

    tq_json(405, ['message' => 'Method not allowed']);
} catch (Exception $e) {
    error_log('TravelQuest comments API error: ' . $e->getMessage());
    tq_json(500, ['message' => 'TravelQuest API error']);
}
PHP

cat > /var/www/html/402/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>TravelQuest 402 Trial</title>
  <style>
    :root { --ink:#1d2733; --muted:#5d6875; --line:#d7dde5; --brand:#116466; --accent:#d94f30; --paper:#fff; --wash:#f5f7f8; }
    * { box-sizing:border-box; }
    body { margin:0; font-family:Arial,Helvetica,sans-serif; color:var(--ink); background:var(--wash); }
    header { min-height:44vh; color:white; background:linear-gradient(rgba(10,33,42,.45),rgba(10,33,42,.6)),url("https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=1800&q=80") center/cover; padding:20px clamp(18px,5vw,72px) 58px; }
    nav { display:flex; justify-content:space-between; gap:16px; align-items:center; font-size:15px; }
    nav a { color:white; text-decoration:none; margin-left:16px; font-weight:700; }
    h1 { margin:90px 0 12px; max-width:760px; font-size:clamp(38px,7vw,72px); line-height:1; }
    .lede { max-width:680px; font-size:19px; line-height:1.55; margin:0; }
    main, footer { width:min(1160px,calc(100% - 32px)); margin-left:auto; margin-right:auto; }
    main { margin-top:-34px; margin-bottom:48px; }
    .panel,.destination,form { background:var(--paper); border:1px solid var(--line); border-radius:8px; box-shadow:0 14px 35px rgba(23,35,48,.08); }
    .panel { padding:18px; margin-bottom:18px; display:grid; gap:14px; grid-template-columns:minmax(220px,1fr) auto auto; align-items:end; }
    label { display:block; font-size:13px; font-weight:700; color:var(--muted); margin-bottom:6px; }
    input,textarea { width:100%; min-height:42px; border:1px solid var(--line); border-radius:6px; padding:10px 11px; font:inherit; }
    textarea { min-height:96px; resize:vertical; }
    button { min-height:42px; border:0; border-radius:6px; padding:0 16px; color:white; background:var(--brand); font-weight:700; cursor:pointer; }
    button.secondary { background:var(--accent); }
    .toolbar { display:flex; justify-content:space-between; align-items:center; gap:16px; margin:22px 0 14px; }
    .toolbar h2,form h2 { margin:0 0 4px; }
    .status { color:var(--muted); margin:0; }
    .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(270px,1fr)); gap:18px; }
    .destination { overflow:hidden; }
    .destination img { width:100%; aspect-ratio:16/10; object-fit:cover; display:block; background:#d8e0e7; }
    .destination .body, form { padding:16px; }
    .comments { margin-top:14px; border-top:1px solid var(--line); padding-top:12px; }
    .comment { margin:0 0 8px; color:var(--muted); font-size:14px; }
    form { margin-top:22px; }
    .fields { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:14px; }
    .full { grid-column:1/-1; }
    .inline-form { display:grid; grid-template-columns:1fr; gap:8px; margin-top:12px; padding:0; border:0; box-shadow:none; }
    footer { margin-bottom:32px; color:var(--muted); font-size:14px; }
    @media (max-width:720px) { .panel,.fields { grid-template-columns:1fr; } .toolbar { align-items:flex-start; flex-direction:column; } h1 { margin-top:58px; } }
  </style>
</head>
<body>
  <header>
    <nav><strong>TravelQuest 402 Trial</strong><span><a href="/">CivicNexus</a><a href="/api/402/health.php">API health</a></span></nav>
    <section><h1>Explore Australia</h1><p class="lede">A small 402AZ TravelQuest recreation served from the 503AZ web server and backed by the private MongoDB replica set.</p></section>
  </header>
  <main>
    <section class="panel">
      <div><label for="token">API token</label><input id="token" type="password" autocomplete="off"></div>
      <button id="save-token" type="button">Save token</button>
      <button id="check-health" class="secondary" type="button">Check API</button>
    </section>
    <section class="toolbar"><div><h2>Destinations</h2><p class="status" id="status">Waiting for API access.</p></div><button id="refresh" type="button">Refresh</button></section>
    <section id="destinations" class="grid"></section>
    <form id="destination-form">
      <h2>Add destination</h2>
      <div class="fields">
        <div><label for="name">Name</label><input id="name" name="name" required></div>
        <div><label for="location">Location</label><input id="location" name="location" value="Australia"></div>
        <div class="full"><label for="imageUrl">Image URL</label><input id="imageUrl" name="imageUrl" value="https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=1200&q=80"></div>
        <div class="full"><label for="description">Description</label><textarea id="description" name="description"></textarea></div>
      </div>
      <p><button type="submit">Add destination</button></p>
    </form>
  </main>
  <footer>TravelQuest trial API: PHP endpoints under /api/402/ with bearer-token authentication.</footer>
  <script>
    const statusEl=document.getElementById('status'),gridEl=document.getElementById('destinations'),formEl=document.getElementById('destination-form'),tokenEl=document.getElementById('token');
    const storedToken=sessionStorage.getItem('travelquestApiToken')||''; tokenEl.value=storedToken;
    function escapeHtml(v){return String(v||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
    async function api(path,options){const token=sessionStorage.getItem('travelquestApiToken')||'',request=options||{},headers=new Headers(request.headers||{}); if(token) headers.set('Authorization','Bearer '+token); const response=await fetch(path,Object.assign({},request,{headers})); const text=await response.text(); let body={}; if(text) body=JSON.parse(text); if(!response.ok) throw new Error(body.message||('API request failed with status '+response.status)); return body;}
    function renderDestination(item){const card=document.createElement('article'); card.className='destination'; const imageUrl=item.imageUrl||'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=1200&q=80'; card.innerHTML='<img src="'+escapeHtml(imageUrl)+'" alt=""><div class="body"><h3>'+escapeHtml(item.name)+'</h3><p><strong>'+escapeHtml(item.location||'Australia')+'</strong></p><p>'+escapeHtml(item.description||'No description added yet.')+'</p><div class="comments"><p class="comment">Loading comments...</p></div><form class="inline-form"><input name="author" placeholder="Name" value="Visitor"><input name="text" placeholder="Comment" required><button type="submit">Add comment</button></form></div>'; const commentsEl=card.querySelector('.comments'),commentForm=card.querySelector('.inline-form'); loadComments(item.id,commentsEl); commentForm.addEventListener('submit',async e=>{e.preventDefault(); const data=new FormData(commentForm); await api('/api/402/comments.php?destinationId='+encodeURIComponent(item.id),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({author:data.get('author')||'Visitor',text:data.get('text')||''})}); commentForm.reset(); await loadComments(item.id,commentsEl);}); return card;}
    async function loadComments(destinationId,container){try{const body=await api('/api/402/comments.php?destinationId='+encodeURIComponent(destinationId)),comments=body.items||[]; if(!comments.length){container.innerHTML='<p class="comment">No comments yet.</p>'; return;} container.innerHTML=comments.map(c=>'<p class="comment"><strong>'+escapeHtml(c.author)+'</strong>: '+escapeHtml(c.text)+'</p>').join('');}catch(err){container.innerHTML='<p class="comment">'+escapeHtml(err.message)+'</p>';}}
    async function loadDestinations(){gridEl.innerHTML=''; try{const body=await api('/api/402/destinations.php'),items=body.items||[]; if(!items.length){statusEl.textContent='No destinations have been added yet.'; return;} items.forEach(item=>gridEl.appendChild(renderDestination(item))); statusEl.textContent='Loaded '+items.length+' destinations from MongoDB.';}catch(err){statusEl.textContent=err.message;}}
    document.getElementById('save-token').addEventListener('click',()=>{sessionStorage.setItem('travelquestApiToken',tokenEl.value.trim()); statusEl.textContent='Token saved for this browser session.'; loadDestinations();});
    document.getElementById('check-health').addEventListener('click',async()=>{try{const body=await api('/api/402/health.php'); statusEl.textContent='API status: '+body.status+', database: '+body.database+'.';}catch(err){statusEl.textContent=err.message;}});
    document.getElementById('refresh').addEventListener('click',loadDestinations);
    formEl.addEventListener('submit',async e=>{e.preventDefault(); const data=new FormData(formEl); try{await api('/api/402/destinations.php',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:data.get('name')||'',location:data.get('location')||'',imageUrl:data.get('imageUrl')||'',description:data.get('description')||''})}); formEl.reset(); await loadDestinations();}catch(err){statusEl.textContent=err.message;}});
    if(storedToken) loadDestinations();
  </script>
</body>
</html>
HTML

chown -R apache:apache /var/www/html/402 /var/www/html/api/402
chmod -R 0755 /var/www/html/402 /var/www/html/api/402
chmod 0640 /var/www/html/api/402/config.php
find /var/www/html/402 /var/www/html/api/402 -type f ! -name config.php -exec chmod 0644 {} \;

