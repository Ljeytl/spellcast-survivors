shader_type canvas_item;
render_mode unshaded, blend_add;
uniform vec2 extent;
uniform vec2 center;
uniform float age;
uniform float warning = 0.65;
uniform float reach;
uniform float strength = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 vec2 p=UV*extent-center; float r=length(p); float angle=atan(p.y,p.x);
 float t=max(0.0,age-warning); float charge=clamp(age/warning,0.0,1.0);
 vec3 purple=vec3(0.47,0.08,1.0); vec3 hot=vec3(0.92,0.72,1.0);
 float n=noise(p*0.025+vec2(t*5.0,-t*3.0));
 float n2=noise(p*0.06-vec2(t*9.0,t*4.0));
 float light=0.0; float white=0.0;
 if(age<warning) {
  float core=exp(-r*r/(40.0+charge*145.0));
  float gather=110.0*(1.0-charge*charge)+16.0;
  float filaments=pow(max(0.0,sin(angle*7.0+r*0.035-age*7.0+noise(p*0.018)*3.0)),18.0);
  light=core*(0.3+charge*0.8)+filaments*exp(-pow((r-gather)/35.0,2.0))*charge*0.5;
  white=core*charge*0.7;
 } else {
  float fade=pow(max(0.0,1.0-t/0.52),2.0);
  float front=reach*(1.0-pow(max(0.0,1.0-t/0.34),2.0));
  float warped=r+(n-0.5)*22.0+(n2-0.5)*8.0;
  float rim=exp(-pow((warped-front)/15.0,2.0));
  float body=exp(-pow((warped-front+22.0)/42.0,2.0));
  float core=exp(-r*r/pow(30.0+t*600.0,2.0))*pow(max(0.0,1.0-t/0.18),2.0);
  light=(body*(0.25+n*0.65)+rim*0.8)*fade+core*1.8;
  white=rim*fade*(0.2+n2*0.65)+core*2.0;
 }
 vec3 color=purple*light+hot*white;
 COLOR=vec4(color*strength,clamp((light+white)*strength,0.0,1.0));
}
