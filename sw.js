/* 银川十八中贴吧 - Service Worker（PWA 离线缓存） */
const CACHE_NAME='yc18-bbs-v1';
const ASSETS=[
  './',
  './index.html',
  './manifest.json',
  './logo.png',
  './school-gate.jpg'
];

self.addEventListener('install',e=>{
  e.waitUntil(
    caches.open(CACHE_NAME).then(c=>c.addAll(ASSETS)).catch(()=>{})
  );
  self.skipWaiting();
});

self.addEventListener('activate',e=>{
  e.waitUntil(
    caches.keys().then(keys=>Promise.all(
      keys.filter(k=>k!==CACHE_NAME).map(k=>caches.delete(k))
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch',e=>{
  const url=new URL(e.request.url);
  /* 仅缓存同源 GET 请求；API/跨域请求直接走网络 */
  if(e.request.method!=='GET'||url.origin!==location.origin){
    return;
  }
  e.respondWith(
    caches.match(e.request).then(cached=>{
      if(cached)return cached;
      return fetch(e.request).then(res=>{
        /* 只缓存成功响应的静态资源 */
        if(res.ok&&(res.type==='basic'||res.type==='default')){
          const clone=res.clone();
          caches.open(CACHE_NAME).then(c=>c.put(e.request,clone));
        }
        return res;
      }).catch(()=>{
        /* 离线时回退到缓存首页 */
        if(e.request.mode==='navigate')return caches.match('./index.html');
        return Response.error();
      });
    })
  );
});
