shader_type canvas_item;
render_mode unshaded;
varying vec4 item_color;
void vertex(){item_color=COLOR;}

uniform float spiritState = 0.0;
uniform float hybrid;uniform vec2 faceCenter;uniform vec2 faceHeading;uniform float faceRadius;uniform vec3 faceGaze;uniform float faceBlink;uniform sampler2D field;uniform vec2 origin;uniform float span;uniform float silhouette;
void fragment(){vec2 point=origin+UV*span;vec2 uv=UV;vec3 d=texture(field,uv).rgb;
float density=d.r;vec2 e=vec2(1./512.,0.);vec2 gradient=vec2(texture(field,uv+e.xy).r-texture(field,uv-e.xy).r,texture(field,uv+e.yx).r-texture(field,uv-e.yx).r);
vec3 n=normalize(vec3(-gradient.x*45.,-gradient.y*45.,.2));float light=dot(n,normalize(vec3(-.4,-.6,.8)))*.5+.5;
float fold=exp(-pow((density-.22)/.12,2.))*.40*smoothstep(.3,.8,light)+exp(-pow((density-.55)/.18,2.))*.16;
vec3 cool=mix(vec3(.19,.43,.48),vec3(.68,.91,.84),light);float heat=smoothstep(.02,.66,d.g);
float inner=exp(-pow((d.b-.11)/.07,2.))*smoothstep(.04,.15,density);vec3 color=mix(cool,vec3(1.,.97,.74),heat)+vec3(.18,.24,.20)*fold;color=mix(color,vec3(.76,.94,.85),inner*.25*(1.-heat));
vec3 faceColor=vec3(.94,.97,.85);
if(spiritState>.5){
vec3 dark=spiritState>1.5?vec3(.48,.025,.10):vec3(.025,.38,.18);
vec3 bright=spiritState>1.5?vec3(1.,.16,.28):vec3(.22,1.,.58);
faceColor=spiritState>1.5?vec3(1.,.42,.46):vec3(.78,1.,.86);
color=mix(dark,bright,light);color=mix(color,faceColor,heat*.7)+fold*(spiritState>1.5?vec3(.24,.12,.06):vec3(.10,.24,.17));
}
float alpha=clamp(smoothstep(.04,.16,density)*.72+fold*.42,0.,.95);
if(hybrid>.5){
alpha*=smoothstep(.001,.025,density);
vec2 q=(point-faceCenter)/faceRadius;float rr=dot(q,q);float rear=smoothstep(-.25,.70,-dot(q,faceHeading));float face=1.-smoothstep(.58-.34*rear,1.12+.65*rear,sqrt(rr));color=mix(color,faceColor,face*.96*(1.-.40*rear));alpha=max(alpha,face*.97*(1.-.12*rear));
vec3 radial=normalize(vec3(q,sqrt(max(.001,1.-rr)))),f=normalize(faceGaze),right=normalize(cross(vec3(0.,1.,0.),f)),up=normalize(cross(f,right));vec2 eyeUV=vec2(dot(radial,right),dot(radial,up));float eye=0.,shine=0.;
for(int i=0;i<2;i++){float side=float(i)*2.-1.;vec2 a=(eyeUV-vec2(side*.28,.04))/vec2(.14+side*.01,(.24+side*.015)*max(.08,1.-faceBlink));eye=max(eye,1.-smoothstep(.9,1.1,dot(a,a)));vec2 b=(eyeUV-vec2(side*.28-.025,-.03))/vec2(.025,.04);shine=max(shine,1.-smoothstep(.7,1.1,dot(b,b)));}
eye*=smoothstep(.72,.82,dot(radial,f))*(1.-smoothstep(.9,1.05,rr));color=mix(color,vec3(.045,.15,.20),eye);color+=vec3(.22,.35,.36)*shine*eye*(1.-faceBlink);
}
if(silhouette>.5){color=vec3(.025,.045,.035);alpha=smoothstep(.035,.07,density);}COLOR=vec4(color,alpha)*item_color;
}