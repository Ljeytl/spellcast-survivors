(()=>{
'use strict';
try{
const canvas=document.getElementById('scene'),stage=canvas.parentElement;
const gl=canvas.getContext('webgl',{alpha:true,antialias:true,premultipliedAlpha:false});
if(!gl){document.getElementById('state').textContent='This study needs WebGL.';return;}
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x)),mix=(a,b,t)=>a+(b-a)*t,TAU=Math.PI*2;
const smooth=(a,b,x)=>{const t=clamp((x-a)/(b-a),0,1);return t*t*(3-2*t)};
let W=1000,H=600,time=0,last=0,mode='hybrid',demo=false,paused=false,size=1.15,reach=1,followSpeed=1,active=false,hasTarget=false,dirty=true;
let gentle=matchMedia('(prefers-reduced-motion: reduce)').matches;
const pointer={x:500,y:300},status=document.getElementById('state'),announce=document.getElementById('announcement');
canvas.addEventListener('webglcontextlost',e=>{e.preventDefault();paused=true;dirty=false;status.textContent='Graphics context lost. Reload this study.';announce.textContent=status.textContent;});
function program(v,f){const p=gl.createProgram();for(const [type,src] of [[gl.VERTEX_SHADER,v],[gl.FRAGMENT_SHADER,f]]){const s=gl.createShader(type);gl.shaderSource(s,src);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));gl.attachShader(p,s);}gl.linkProgram(p);if(!gl.getProgramParameter(p,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(p));return p;}
const quadVertex=`attribute vec2 position;uniform vec2 viewport;varying vec2 point;void main(){point=position;gl_Position=vec4(position.x/viewport.x*2.-1.,1.-position.y/viewport.y*2.,0.,1.);}`;
const ghostProgram=program(quadVertex,`precision highp float;
varying vec2 point;uniform vec4 nodes[60];uniform vec3 head;uniform vec2 axis;uniform float radius;uniform vec3 gaze;uniform float clock;uniform float blink;uniform float silhouette;
float merge(float a,float b,float k){float h=clamp(.5+.5*(b-a)/k,0.,1.);return mix(b,a,h)-k*h*(1.-h);}
void main(){vec2 local=(point-head.xy)/radius;float distance=(length(local)-1.)*radius;float foldLight=0.,foldWeight=0.;
for(int j=0;j<3;j++){
float best=10000.,across=0.,along=0.,samples=0.;
for(int i=0;i<19;i++){vec2 a=nodes[j*20+i].xy,b=nodes[j*20+i+1].xy,ab=b-a;float t=clamp(dot(point-a,ab)/max(dot(ab,ab),.01),0.,1.);vec2 delta=point-mix(a,b,t);float width=mix(nodes[j*20+i].w,nodes[j*20+i+1].w,t);float metric=length(delta)-width;best=min(best,metric);float w=exp(-dot(delta,delta)/(radius*radius*.28));across+=dot(delta,vec2(-ab.y,ab.x)/max(length(ab),.001))/max(width,.3)*w;along+=(float(i)+t)/19.*w;samples+=w;}
across/=max(samples,.00001);along/=max(samples,.00001);distance=merge(distance,best,radius*mix(.34,.10,along));float weight=exp(-max(best,0.)/radius*5.);float fold=across+.20*sin(along*7.+float(j)*1.7+clock*.5);float crest=smoothstep(-.65,-.22,fold)*(1.-smoothstep(.12,.65,fold));float seam=smoothstep(.30,.43,fold)*(1.-smoothstep(.51,.65,fold));foldLight+=(crest*.65-seam*.28)*weight;foldWeight+=weight;
}
float alpha=1.-smoothstep(-.9,.9,distance);if(alpha<.005)discard;
float rear=-dot(local,axis);float material=smoothstep(-.5,1.6,rear);float fold=foldLight/max(foldWeight,.001);vec3 color=mix(vec3(.43,.61,.65),vec3(.78,.87,.82),clamp(.25+fold,0.,1.));
float wash=smoothstep(-.7,.65,-local.y-local.x*.2);vec3 face=mix(vec3(.82,.89,.81),vec3(.98,.97,.85),wash);color=mix(face,color,material*.90);alpha*=mix(1.,.52,smoothstep(.8,3.4,rear));
float rr=dot(local,local);vec3 radial=normalize(vec3(local,sqrt(max(.001,1.-rr)))),f=normalize(gaze),right=normalize(cross(vec3(0.,1.,0.),f)),up=normalize(cross(f,right));vec2 uv=vec2(dot(radial,right),dot(radial,up));float front=dot(radial,f),eyes=0.,glint=0.;
for(int i=0;i<2;i++){float side=float(i)*2.-1.;vec2 q=(uv-vec2(side*.27,.04))/vec2(.145+side*.009,(.245+side*.015)*max(.08,1.-blink));eyes=max(eyes,1.-smoothstep(.93,1.07,dot(q,q)));vec2 h=(uv-vec2(side*.27-.025,-.025))/vec2(.022,.038);glint=max(glint,1.-smoothstep(.75,1.1,dot(h,h)));}
eyes*=smoothstep(.72,.80,front)*(1.-smoothstep(.95,1.05,rr));color=mix(color,vec3(.045,.15,.20),eyes);color+=vec3(.25,.39,.40)*glint*eyes*(1.-blink);
if(silhouette>.5){color=vec3(.025,.045,.035);alpha=1.;}gl_FragColor=vec4(color,alpha);
}`);
const fluidProgram=program(quadVertex,`precision highp float;
uniform sampler2D previous;uniform vec2 origin;uniform vec2 oldOrigin;uniform float span;uniform float oldSpan;uniform vec2 source;uniform vec2 oldSource;uniform vec2 heading;uniform float radius;uniform float dt;uniform float trailWidth;uniform float reach;uniform float clock;
void main(){vec2 uv=gl_FragCoord.xy/512.;vec2 world=origin+vec2(uv.x,1.-uv.y)*span;vec2 q=world-source;float d=length(q);vec2 tangent=vec2(-q.y,q.x)/max(d,1.);
float freq=.055;vec2 curl=vec2(-sin(world.x*freq+clock*.8)*sin(world.y*freq-clock*.6),-cos(world.x*freq+clock*.8)*cos(world.y*freq-clock*.6));
vec2 velocity=tangent*radius*2.8*exp(-d/(radius*1.5))+curl*radius*1.2-heading*radius*1.15+vec2(0.,-radius*.75);
vec2 previousPoint=world-velocity*dt;vec2 sampleUV=(previousPoint-oldOrigin)/oldSpan;sampleUV.y=1.-sampleUV.y;
vec4 value=texture2D(previous,sampleUV);if(any(lessThan(sampleUV,vec2(0.)))||any(greaterThan(sampleUV,vec2(1.))))value=vec4(0.);
value.r*=exp(-dt*(2.0/reach+smoothstep(radius*2.*reach,radius*4.*reach,d)*5.));value.g*=exp(-dt*8.);value.b*=exp(-dt*2.8);
vec2 ab=source-oldSource;float h=clamp(dot(world-oldSource,ab)/max(dot(ab,ab),.01),0.,1.);vec2 center=mix(oldSource,source,h);vec2 local=(world-center)/radius;vec2 across=vec2(-heading.y,heading.x);local-=across*dot(local,across)*(1.-1./trailWidth);
local.x+=.13*sin(local.y*2.+clock*.8);local.y*=1.15;float body=exp(-dot(local,local)*3.1);
value.r+=body*dt*4.2;vec2 core=(world-source)/radius;float sourceHeat=exp(-dot(core,core)*3.8)*(1.+.12*sin(core.x*6.+clock)*sin(core.y*5.-clock));value.g=max(value.g,sourceHeat*.9);vec2 veil=local-vec2(.22*sin(clock*.8),-.22);value.b+=exp(-dot(veil*vec2(1.4,.85),veil*vec2(1.4,.85))*7.)*dt*3.4;gl_FragColor=vec4(clamp(value.rgb,0.,1.),1.);
}`);
const wispProgram=program(quadVertex,`precision highp float;
uniform float hybrid;uniform vec2 faceCenter;uniform vec2 faceHeading;uniform float faceRadius;uniform vec3 faceGaze;uniform float faceBlink;uniform sampler2D field;uniform vec2 origin;uniform float span;uniform float silhouette;varying vec2 point;
void main(){vec2 uv=(point-origin)/span;uv.y=1.-uv.y;vec3 d=texture2D(field,uv).rgb;
float density=d.r;vec2 e=vec2(1./512.,0.);vec2 gradient=vec2(texture2D(field,uv+e.xy).r-texture2D(field,uv-e.xy).r,texture2D(field,uv+e.yx).r-texture2D(field,uv-e.yx).r);
vec3 n=normalize(vec3(-gradient.x*45.,gradient.y*45.,.2));float light=dot(n,normalize(vec3(-.4,-.6,.8)))*.5+.5;
float fold=exp(-pow((density-.22)/.12,2.))*.40*smoothstep(.3,.8,light)+exp(-pow((density-.55)/.18,2.))*.16;
vec3 cool=mix(vec3(.19,.43,.48),vec3(.68,.91,.84),light);float heat=smoothstep(.02,.66,d.g);
float inner=exp(-pow((d.b-.11)/.07,2.))*smoothstep(.04,.15,density);vec3 color=mix(cool,vec3(1.,.97,.74),heat)+vec3(.18,.24,.20)*fold;color=mix(color,vec3(.76,.94,.85),inner*.25*(1.-heat));
float alpha=clamp(smoothstep(.04,.16,density)*.72+fold*.42,0.,.95);
if(hybrid>.5){
alpha*=smoothstep(.001,.025,density);
vec2 q=(point-faceCenter)/faceRadius;float rr=dot(q,q);float rear=smoothstep(-.10,.85,-dot(q,faceHeading));float face=1.-smoothstep(.58-.18*rear,1.12+.36*rear,sqrt(rr));color=mix(color,vec3(.94,.97,.85),face*.96*(1.-.22*rear));alpha=max(alpha,face*.97);
vec3 radial=normalize(vec3(q,sqrt(max(.001,1.-rr)))),f=normalize(faceGaze),right=normalize(cross(vec3(0.,1.,0.),f)),up=normalize(cross(f,right));vec2 eyeUV=vec2(dot(radial,right),dot(radial,up));float eye=0.,shine=0.;
for(int i=0;i<2;i++){float side=float(i)*2.-1.;vec2 a=(eyeUV-vec2(side*.28,.04))/vec2(.14+side*.01,(.24+side*.015)*max(.08,1.-faceBlink));eye=max(eye,1.-smoothstep(.9,1.1,dot(a,a)));vec2 b=(eyeUV-vec2(side*.28-.025,-.03))/vec2(.025,.04);shine=max(shine,1.-smoothstep(.7,1.1,dot(b,b)));}
eye*=smoothstep(.72,.82,dot(radial,f))*(1.-smoothstep(.9,1.05,rr));color=mix(color,vec3(.045,.15,.20),eye);color+=vec3(.22,.35,.36)*shine*eye*(1.-faceBlink);
}
if(silhouette>.5){color=vec3(.025,.045,.035);alpha=smoothstep(.035,.07,density);}gl_FragColor=vec4(color,alpha);
}`);
const halfFloat=gl.getExtension('OES_texture_half_float');const halfLinear=gl.getExtension('OES_texture_half_float_linear');const halfRender=gl.getExtension('EXT_color_buffer_half_float');
function makeField(){const texture=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,texture);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,512,512,0,gl.RGBA,halfFloat&&halfLinear&&halfRender?halfFloat.HALF_FLOAT_OES:gl.UNSIGNED_BYTE,null);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);const framebuffer=gl.createFramebuffer();gl.bindFramebuffer(gl.FRAMEBUFFER,framebuffer);gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,texture,0);if(gl.checkFramebufferStatus(gl.FRAMEBUFFER)!==gl.FRAMEBUFFER_COMPLETE){gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,512,512,0,gl.RGBA,gl.UNSIGNED_BYTE,null);if(gl.checkFramebufferStatus(gl.FRAMEBUFFER)!==gl.FRAMEBUFFER_COMPLETE)throw Error('Fluid framebuffer unavailable');}gl.bindFramebuffer(gl.FRAMEBUFFER,null);return{texture,framebuffer};}
let fields=[makeField(),makeField()],fieldOrigin=[0,0],fieldSpan=1,oldSource=[0,0],fieldReady=false;
const quadBuffer=gl.createBuffer();
function drawQuad(p,x0,y0,x1,y1){gl.bindBuffer(gl.ARRAY_BUFFER,quadBuffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([x0,y0,x1,y0,x0,y1,x0,y1,x1,y0,x1,y1]),gl.DYNAMIC_DRAW);const a=gl.getAttribLocation(p,'position');gl.enableVertexAttribArray(a);gl.vertexAttribPointer(a,2,gl.FLOAT,false,8,0);gl.drawArrays(gl.TRIANGLES,0,6);}
const loc=(p,n)=>gl.getUniformLocation(p,n);
const GU=Object.fromEntries(['viewport','gaze','clock','blink','silhouette','head','axis','radius','nodes'].map(n=>[n,loc(ghostProgram,n)]));
const WU=Object.fromEntries(['viewport','field','origin','span','silhouette','hybrid','faceCenter','faceHeading','faceRadius','faceGaze','faceBlink'].map(n=>[n,loc(wispProgram,n)]));
const FU=Object.fromEntries(['viewport','previous','origin','oldOrigin','span','oldSpan','source','oldSource','heading','radius','dt','trailWidth','reach','clock'].map(n=>[n,loc(fluidProgram,n)]));
function create(kind){return{kind,x:0,y:0,vx:0,vy:0,angle:-.2,speed:0,turn:0,gx:.25,gy:.05,ready:false};}
const spirits=[create('ghost'),create('wisp'),create('hybrid')];let silhouette=false;
function resize(){const b=stage.getBoundingClientRect();W=b.width;H=b.height;const dpr=Math.min(devicePixelRatio||1,1.5);canvas.width=Math.round(W*dpr);canvas.height=Math.round(H*dpr);gl.viewport(0,0,canvas.width,canvas.height);pointer.x=clamp(pointer.x,40,W-40);pointer.y=clamp(pointer.y,40,H-90);for(const s of spirits)s.ready=false;dirty=true;}
new ResizeObserver(resize).observe(stage);
function setDemo(v){demo=v;document.getElementById('demo').setAttribute('aria-pressed',String(v));announce.textContent=v?'Demo path running':'Follow pointer';}
function pause(){paused=!paused;const b=document.getElementById('pause');b.textContent=paused?'Resume':'Pause';b.setAttribute('aria-pressed',String(paused));announce.textContent=paused?'Paused':'Resumed';}
function pointerEvent(e){const b=canvas.getBoundingClientRect();pointer.x=clamp(e.clientX-b.left,30,W-30);pointer.y=clamp(e.clientY-b.top,40,H-90);hasTarget=active=true;if(demo)setDemo(false);}
canvas.addEventListener('pointermove',pointerEvent);canvas.addEventListener('pointerdown',e=>{canvas.focus();canvas.setPointerCapture(e.pointerId);pointerEvent(e)});canvas.addEventListener('pointerleave',()=>active=false);
canvas.addEventListener('keydown',e=>{const dirs={ArrowLeft:[-40,0],ArrowRight:[40,0],ArrowUp:[0,-40],ArrowDown:[0,40]};if(dirs[e.key]){e.preventDefault();setDemo(false);hasTarget=active=true;pointer.x=clamp(pointer.x+dirs[e.key][0],30,W-30);pointer.y=clamp(pointer.y+dirs[e.key][1],40,H-90);}if(e.code==='Space'){e.preventDefault();if(!e.repeat)pause();}if(e.key.toLowerCase()==='s'&&!e.repeat){silhouette=!silhouette;dirty=true;}});
document.querySelectorAll('[data-mode]').forEach(b=>b.onclick=()=>{mode=b.dataset.mode;document.querySelectorAll('[data-mode]').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));for(const s of spirits)s.ready=false;dirty=true;announce.textContent=mode;});
document.getElementById('demo').onclick=()=>setDemo(!demo);document.getElementById('pause').onclick=pause;
document.getElementById('size').oninput=e=>{size=+e.target.value;dirty=true};document.getElementById('reach').oninput=e=>{reach=+e.target.value;dirty=true};document.getElementById('follow').oninput=e=>followSpeed=+e.target.value;
document.getElementById('gentle').checked=gentle;document.getElementById('gentle').onchange=e=>gentle=e.target.checked;
function update(s,dt,tx,ty){
const radius=(s.kind==='ghost'?43:38)*size*Math.min(1,W/650);s.radius=radius;
if(!s.ready){s.x=tx;s.y=ty;s.vx=s.vy=0;s.nodes=null;s.ready=true;if(s.kind!=='ghost')fieldReady=false;}
const dx=tx-s.x,dy=ty-s.y,distance=Math.hypot(dx,dy);
const k=(gentle?17:30)*followSpeed,drag=2*Math.sqrt(k)*.88;
s.vx+=(dx*k-s.vx*drag)*dt;s.vy+=(dy*k-s.vy*drag)*dt;
const speed=Math.hypot(s.vx,s.vy),limit=gentle?600:1100;if(speed>limit){s.vx*=limit/speed;s.vy*=limit/speed;}
s.x+=s.vx*dt;s.y+=s.vy*dt;s.speed=mix(s.speed,Math.hypot(s.vx,s.vy),1-Math.exp(-dt*7));
if(s.speed>22){const desired=Math.atan2(s.vy,s.vx),difference=Math.atan2(Math.sin(desired-s.angle),Math.cos(desired-s.angle));s.turn=mix(s.turn,difference,1-Math.exp(-dt*5));s.angle+=difference*(1-Math.exp(-dt*4.5));}else s.turn*=Math.exp(-dt*5);
const gazeScale=Math.min(.82,distance/95);const gx=distance>4?dx/distance*gazeScale:s.gx*.998,gy=distance>4?dy/distance*gazeScale*.75:s.gy*.998;
s.gx=mix(s.gx,gx,1-Math.exp(-dt*13));s.gy=mix(s.gy,gy,1-Math.exp(-dt*13));

}
function drawGhost(s,dt){
const r=s.radius,nodes=new Float32Array(240),ca=Math.cos(s.angle),sa=Math.sin(s.angle),bob=Math.sin(time*1.7)*r*.045;
let minX=s.x-r*1.5,maxX=s.x+r*1.5,minY=s.y-r*1.5,maxY=s.y+r*1.5;
for(let j=0;j<3;j++)for(let i=0;i<20;i++){
const u=i/19,phi=j*TAU/3+time*.22,turn=s.turn*u*.45;
const length=[2.65,2.25,2.9][j]*r*reach*(1+clamp(s.speed/700,0,1)*.30);
const hook=smooth(.60,1,u);const back=-r*.20+length*u-(1-Math.cos(hook*Math.PI))*r*.18;
const side=Math.cos(phi)*r*(.40+Math.sin(u*Math.PI)*.50)+Math.sin(time*1.2-u*4+j)*r*.30*u+Math.sin(hook*Math.PI)*r*.40*(j===1?-1:1)+s.turn*r*u*.7;
const a=s.angle-turn,x=s.x-Math.cos(a)*back-Math.sin(a)*side,y=s.y-Math.sin(a)*back+Math.cos(a)*side+bob,z=Math.sin(phi)*r*.28*(1-u)+Math.sin(u*5-time*.7+j)*r*.23*Math.sin(u*Math.PI);
const width=r*[.78,.72,.65][j]*Math.pow(1-u,1.5)+.4;
if(!s.nodes)s.nodes=[];const index=j*20+i;let node=s.nodes[index];
if(!node||i===0){node={x,y,z};s.nodes[index]=node;}else{const response=1-Math.exp(-dt*(22-14*u));node.x=mix(node.x,x,response);node.y=mix(node.y,y,response);node.z=mix(node.z,z,response);const prev=s.nodes[index-1],dx=node.x-prev.x,dy=node.y-prev.y,dz=node.z-prev.z,dist=Math.hypot(dx,dy,dz),limit=length/19*1.8;if(dist>limit){node.x=prev.x+dx/dist*limit;node.y=prev.y+dy/dist*limit;node.z=prev.z+dz/dist*limit;}}
nodes.set([node.x,node.y,node.z,width],index*4);minX=Math.min(minX,node.x-width*1.4);maxX=Math.max(maxX,node.x+width*1.4);minY=Math.min(minY,node.y-width*1.4);maxY=Math.max(maxY,node.y+width*1.4);
}
gl.useProgram(ghostProgram);gl.uniform2f(GU.viewport,W,H);gl.uniform3f(GU.head,s.x,s.y+bob,0);gl.uniform2f(GU.axis,ca,sa);gl.uniform1f(GU.radius,r);gl.uniform4fv(GU.nodes,nodes);gl.uniform3f(GU.gaze,s.gx,s.gy,Math.sqrt(Math.max(.12,1-s.gx*s.gx-s.gy*s.gy)));gl.uniform1f(GU.clock,time);gl.uniform1f(GU.blink,Math.pow(Math.max(0,Math.cos(time*1.1+1.5)),70));gl.uniform1f(GU.silhouette,silhouette?1:0);drawQuad(ghostProgram,minX,minY,maxX,maxY);
}
function drawWisp(s,dt){
const span=s.radius*12,origin=[s.x-span/2,s.y-span/2];
if(!fieldReady){for(const f of fields){gl.bindFramebuffer(gl.FRAMEBUFFER,f.framebuffer);gl.clearColor(0,0,0,1);gl.clear(gl.COLOR_BUFFER_BIT);}fieldOrigin=origin.slice();fieldSpan=span;oldSource=[s.x,s.y];fieldReady=true;dt=Math.max(dt,.15);}
if(dt>0){
gl.disable(gl.BLEND);gl.bindFramebuffer(gl.FRAMEBUFFER,fields[1].framebuffer);gl.viewport(0,0,512,512);gl.useProgram(fluidProgram);gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,fields[0].texture);gl.uniform1i(FU.previous,0);gl.uniform2f(FU.viewport,512,512);gl.uniform2fv(FU.origin,origin);gl.uniform2fv(FU.oldOrigin,fieldOrigin);gl.uniform1f(FU.span,span);gl.uniform1f(FU.oldSpan,fieldSpan);gl.uniform2f(FU.source,s.x,s.y);gl.uniform2fv(FU.oldSource,oldSource);gl.uniform2f(FU.heading,Math.cos(s.angle),Math.sin(s.angle));gl.uniform1f(FU.radius,s.radius);gl.uniform1f(FU.dt,dt*(gentle?.55:1));gl.uniform1f(FU.trailWidth,s.kind==='hybrid'?1.65:1.);gl.uniform1f(FU.reach,reach);gl.uniform1f(FU.clock,time);drawQuad(fluidProgram,0,0,512,512);fields.reverse();fieldOrigin=origin.slice();fieldSpan=span;oldSource=[s.x,s.y];
}
gl.bindFramebuffer(gl.FRAMEBUFFER,null);gl.viewport(0,0,canvas.width,canvas.height);gl.enable(gl.BLEND);gl.useProgram(wispProgram);gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,fields[0].texture);gl.uniform1i(WU.field,0);gl.uniform1f(WU.hybrid,s.kind==='hybrid'?1:0);gl.uniform2f(WU.faceCenter,s.x,s.y);gl.uniform2f(WU.faceHeading,Math.cos(s.angle),Math.sin(s.angle));gl.uniform1f(WU.faceRadius,s.radius*.85);gl.uniform3f(WU.faceGaze,s.gx,s.gy,Math.sqrt(Math.max(.12,1-s.gx*s.gx-s.gy*s.gy)));gl.uniform1f(WU.faceBlink,Math.pow(Math.max(0,Math.cos(time*1.1+1.5)),70));gl.uniform2f(WU.viewport,W,H);gl.uniform2fv(WU.origin,fieldOrigin);gl.uniform1f(WU.span,fieldSpan);gl.uniform1f(WU.silhouette,silhouette?1:0);drawQuad(wispProgram,fieldOrigin[0],fieldOrigin[1],fieldOrigin[0]+fieldSpan,fieldOrigin[1]+fieldSpan);
}
function frame(now){const elapsed=Math.min((now-last)/1000||1/60,.05);last=now;if(!paused||dirty){const dt=paused?0:elapsed;dirty=false;time+=dt*(gentle?.45:1);
let tx=pointer.x,ty=pointer.y;if(demo){tx=W*.52+Math.cos(time*.65)*W*.24;ty=H*.43+Math.sin(time*.92)*H*.21;}else if(!hasTarget){tx=W*.58;ty=H*.44;}
const selected=spirits.filter(s=>(mode==='both'&&s.kind!=='hybrid')||mode===s.kind),steps=Math.max(1,Math.ceil(dt*120));
for(let n=0;n<steps;n++)for(const s of selected){const offset=mode==='both'?(s.kind==='ghost'?-1:1)*Math.min(125,W*.20):0;update(s,dt/steps,clamp(tx+offset,70,W-70),clamp(ty,65,H-105));}
gl.clearColor(.13,.205,.17,1);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);gl.enable(gl.BLEND);gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA);
for(const s of selected){if(s.kind==='ghost')drawGhost(s,dt);else drawWisp(s,dt);}
const fastest=Math.max(...selected.map(s=>s.speed)),turn=Math.max(...selected.map(s=>Math.abs(s.turn)));status.textContent=fastest<25?'Gathering':turn>.45?'Turning':fastest>240?'Pursuing':'Drifting';
}requestAnimationFrame(frame);}
requestAnimationFrame(frame);
window.spiritStudy={snapshot:()=>({mode,paused,demo,time,width:W,height:H,spirits:spirits.map(s=>({kind:s.kind,x:s.x,y:s.y,speed:s.speed,angle:s.angle,gaze:[s.gx,s.gy],nodes:s.nodes?s.nodes.map(p=>({...p})):[],fieldReady:s.kind!=='ghost'?fieldReady:undefined}))}),silhouette:()=>{silhouette=!silhouette;dirty=true}};
}catch(error){document.getElementById('state').textContent='Renderer unavailable on this browser. Try a WebGL-capable desktop browser.';console.error(error);}
})();
