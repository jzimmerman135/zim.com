#define MAX_STEPS 1000
#define MAX_DIST 50.
#define SURF_DIST .0001
#define TAU 6.283185
#define PI 3.141592

#define BOX 2.
#define WATER 1.
#define SKY 3.

#define STEPS 100.0
#define MDIST 40.0
#define TAU 6.283185
#define PI 3.141592




#define ITERS_TRACE 3
#define ITERS_NORM 5

#define HOR_SCALE 1.
#define OCC_SPEED 1.3
#define SCRL_SPEED .5

#define DX_DET .65

#define FREQ 0.8
#define HEIGHT_DIV 1.9
#define WEIGHT_SCL 0.3
#define FREQ_SCL 1.4
#define TIME_SCL .3
#define WAV_ROT 1.2
#define DRAG .4
#define WAV_DIR vec2(0, 1)

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

mat3 Rot3d(vec3 a, vec3 b) {
    vec3 v = cross(a, b);
    float c = dot(a, b);
    mat3 I = mat3(1, 0, 0, 0, 1, 0, 0, 0, 1);         
    mat3 m = mat3(0, -v.z, v.y, v.z, 0, -v.x, -v.y, v.x, 0);
    return I + m + m * m / (1. + c);
}

vec2 WaveDx(vec2 wavPos, int iters, float t){
    vec2 dx = vec2(0);
    vec2 wavDir = WAV_DIR;
    float wavWeight = 1.0; 
    wavPos+= t*SCRL_SPEED;
    wavPos*= HOR_SCALE;
    float wavFreq = FREQ;
    float wavTime = OCC_SPEED*t;
    for(int i=0;i<iters;i++){
        wavDir*=Rot(WAV_ROT);
        float x = dot(wavDir,wavPos)*wavFreq+wavTime; 
        float result = exp(sin(x)-1.)*cos(x);
        result*=wavWeight;
        dx+= result*wavDir/pow(wavWeight,DX_DET); 
        wavFreq*= FREQ_SCL; 
        wavTime*= TIME_SCL;
        wavPos-= wavDir*result*DRAG; 
        wavWeight*= WEIGHT_SCL;
    } 
    float wavSum = -(pow(WEIGHT_SCL,float(iters))-1.)*HEIGHT_DIV; 
    return dx/pow(wavSum,1.-DX_DET);
}

float Wave(vec2 wavPos, int iters, float t){
    float wav = 0.0;
    vec2 wavDir = WAV_DIR;
    float wavWeight = 1.0;
    wavPos+= t*SCRL_SPEED;
    wavPos*= HOR_SCALE; 
    float wavFreq = FREQ;
    float wavTime = OCC_SPEED*t;
    for(int i=0;i<iters;i++){
        wavDir*=Rot(WAV_ROT);
        float x = dot(wavDir,wavPos)*wavFreq+wavTime;
        float wave = exp(sin(x)-1.0)*wavWeight;
        wav+= wave;
        wavFreq*= FREQ_SCL;
        wavTime*= TIME_SCL;
        wavPos-= wavDir*wave*DRAG*cos(x);
        wavWeight*= WEIGHT_SCL;
    }
    float wavSum = -(pow(WEIGHT_SCL,float(iters))-1.)*HEIGHT_DIV; 
    return wav/wavSum;
}

vec3 WaveNorm(vec3 p){
    vec2 wav = -WaveDx(p.xz, ITERS_NORM, iTime);
    return normalize(vec3(wav.x,2.0,wav.y));
}

float sdLink( vec3 p, float le, float r1, float r2 )
{
  vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
  return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float sdPlane(vec3 p)
{
    float d = p.y - Wave(p.xz,ITERS_TRACE, iTime);
    return d;
}

vec2 GetDist(vec3 p) {
    vec3 co = p - vec3(4, 1, 4);
        
        co.zx *= Rot(iTime);
         
    //float dBox = sdBox(co, vec3(.5, .5, 5));
    float dBox = sdLink(co, 1., 1., .4);
    float dPln = sdPlane(p);
    
    if (dBox < dPln) 
        return vec2(dBox, BOX);
    return vec2(dPln, WATER);
}

vec2 RayMarch(vec3 ro, vec3 rd) {
	float dO=0.;
    
    // collision.x = dist to collision
    // collision.y = object from collision
    vec2 collision = vec2(0); 
    
    for(int i=0; i< MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        collision = GetDist(p);
        dO += collision.x; // dist to collision
        if(dO > MAX_DIST)
            return vec2(dO, SKY);
            
        if (abs(collision.x) < SURF_DIST) 
            break;
    }
    
    return vec2(dO, collision.y);
}

vec3 GetNormal(vec3 p) {
    vec2 e = vec2(.001, 0);
    vec3 n = GetDist(p).x - vec3(GetDist(p-e.xyy).x,
                                 GetDist(p-e.yxy).x,
                                 GetDist(p-e.yyx).x);
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 
        f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u;
    return normalize(i);
}

const vec3 skyDark = vec3(.02, .01, .1);
const vec3 skyLight = vec3(.06, .05, .40);
const vec3 lightSource = vec3(1000000, 200000, 0);

vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d){
    return a+b*cos(2.0*PI*(c*t+d));
}

vec3 spc(float n,float bright){
    float t = n;
    vec3 a = vec3(bright);
    return pal(n,vec3(bright),vec3(0.5),vec3(1.1),vec3(0.0,0.25,0.67));
}

vec3 SkyColor(vec3 rd, vec3 ls)
{
    float px = .004;
    float rad = 0.07;
    vec3 col = skyDark;
    vec3 sc = spc(.25 * 1.2,.6)*1.0;
    float a = distance(rd, normalize(ls));
    vec3 sun = smoothstep(a-px,a+px,rad - 0.03)*sc*2.;
    col += sun;
    col += rad/(rad+pow(a + .1,1.7))*sc;
    vec3 p = rd;
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	vec2 m = iMouse.xy/iResolution.xy;

    vec3 ro = vec3(5, 2, -20);
    ro.yz *= Rot(-m.y*PI+1.5);
    ro.xz *= Rot(-m.x*TAU);
    ro.y = clamp(ro.y, 0.0, 50.0);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0,2.,0), 1.);
    vec3 col = vec3(0);
    vec2 march = RayMarch(ro, rd);
    
    float d = march.x;
    float obj = march.y;
    
    col = SkyColor(rd, lightSource);
    vec3 p = ro + rd * d;
    
    if(obj == WATER) {
        vec3 n = WaveNorm(p);
        vec3 rfl = reflect(rd,n); 
        float fres = clamp((pow(1. - max(0.0, dot(-n, rd)), 8.0)),0.0,1.0);
        vec3 skyCol = SkyColor(rfl, lightSource) * fres * 0.9;
        vec3 waterCol = clamp(spc(.05-0.1,1.2), 0., 1.);
        waterCol *= 0.4*pow(min(p.y*0.7+1.2,.9),.5);
        waterCol *= length(rfl)*(rd.z*0.25+0.15);
        col += waterCol * .15;
        col += mix(col, skyCol, d / MDIST);
    }
    else if (obj == BOX) {
        vec3 n = GetNormal(p);
        vec3 rfl = reflect(rd, n);   
        float dif = dot(n, normalize(lightSource))*.5+.5;
        col = vec3(dif);
        col *= vec3(.5, 0, 0);
        col = pow(col, vec3(.45));
        col += SkyColor(rfl, lightSource);
    }
    
    col = pow(col, vec3(.87));	// gamma correction
    col *= 1.0 - 0.8 * pow(length(uv * vec2(0.8,1.)), 2.7);
    
    fragColor = vec4(col,1.0);
}