shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform bool reset = false;
uniform sampler2D previous;uniform vec2 origin;uniform vec2 oldOrigin;uniform float span;uniform float oldSpan;uniform vec2 source;uniform vec2 oldSource;uniform vec2 heading;uniform float radius;uniform float dt;uniform float trailWidth;uniform float reach;uniform float clock;
void fragment(){vec2 uv=UV;vec2 world=origin+uv*span;vec2 q=world-source;float d=length(q);vec2 tangent=vec2(-q.y,q.x)/max(d,1.);
float freq=.055;vec2 curl=vec2(-sin(world.x*freq+clock*.8)*sin(world.y*freq-clock*.6),-cos(world.x*freq+clock*.8)*cos(world.y*freq-clock*.6));
vec2 velocity=tangent*radius*2.8*exp(-d/(radius*1.5))+curl*radius*1.2-heading*radius*1.15+vec2(0.,-radius*.75);
vec2 previousPoint=world-velocity*dt;vec2 sampleUV=(previousPoint-oldOrigin)/oldSpan;
vec4 value=reset ? vec4(0.) : texture(previous,sampleUV);if(any(lessThan(sampleUV,vec2(0.)))||any(greaterThan(sampleUV,vec2(1.))))value=vec4(0.);
value.r*=exp(-dt*(2.0/reach+smoothstep(radius*2.*reach,radius*4.*reach,d)*5.));value.g*=exp(-dt*8.);value.b*=exp(-dt*2.8);
vec2 ab=source-oldSource;float h=clamp(dot(world-oldSource,ab)/max(dot(ab,ab),.01),0.,1.);vec2 center=mix(oldSource,source,h);vec2 local=(world-center)/radius;vec2 across=vec2(-heading.y,heading.x);local-=across*dot(local,across)*(1.-1./trailWidth);
local.x+=.13*sin(local.y*2.+clock*.8);local.y*=1.15;float body=exp(-dot(local,local)*3.1);
value.r+=body*dt*4.2;vec2 core=(world-source)/radius;float sourceHeat=exp(-dot(core,core)*3.8)*(1.+.12*sin(core.x*6.+clock)*sin(core.y*5.-clock));value.g=max(value.g,sourceHeat*.9);vec2 veil=local-vec2(.22*sin(clock*.8),-.22);value.b+=exp(-dot(veil*vec2(1.4,.85),veil*vec2(1.4,.85))*7.)*dt*3.4;COLOR=vec4(clamp(value.rgb,0.,1.),1.);
}