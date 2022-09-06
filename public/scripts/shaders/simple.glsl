#define TAU 6.283185
#define PI 3.141592

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST 0.1

#define ITERS_RAY    10
#define ITERS_NORMAL 30
#define W_DEPTH  1.0
#define W_SPEED  1.1
#define W_DETAIL .4

const float WATER = 1.;
const float SKY = 2.;
const float SCENE_BOX = 3.;
const float SCENE = 4.;

const vec3 sceneObjectColor = vec3(0.8745, 0.1647, 0.1647);
const vec3 waterBaseColor = vec3(0.0706, 0.0588, 0.2353);
const vec3 moonBaseColor = vec3(0.7961, 0.4549, 0.9294);
const vec3 skyDarkColor = vec3(.02, .01, .1);
const vec3 skyLightColor = vec3(.06, .05, .40);
const vec3 fogColor = vec3(0.1843, 0.1569, 0.2627);
const vec3 lightSource = vec3(5500, 1500, -4000);


mat2 Rot(float a)
{
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c); // 2D rotation matrix
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z)
{
    vec3 f = normalize(l-p);
    vec3 r = normalize(cross(vec3(0,1,0), f));
    vec3 u = cross(f,r);
    vec3 c = f * z;
    vec3 i = c + uv.x * r + uv.y * u;
    return normalize(i);
}

vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a+b*cos(2.0*PI*(c*t+d));
}

vec3 spc(float n, float bright) {
    float t = n;
    vec3 a = vec3(bright);
    return pal(n,vec3(bright),vec3(0.5),vec3(1.1),vec3(0.0,0.25,0.67));
}

vec3 SkyColor(vec3 rd)
{
    float px = .004;
    float rad = 0.025;
    float glowRad = 0.07;
    vec3 col = skyDarkColor;
    vec3 sc = spc(.25 * 1.2,.7)*1.0;
    float a = distance(rd, normalize(lightSource));
    vec3 sun = smoothstep(a-px,a+px,rad)*sc*2.;
    col += sun;
    col += glowRad/(glowRad+pow(a + .1,1.7))*sc;
    vec3 p = rd;
    return col;
}

vec3 WaterColor(vec3 rflColor, vec3 ro, vec3 rd, vec3 p)
{
    return rflColor * .5;
}

float sdBox(vec3 p, vec3 s)
{
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}
 
float SceneBoxDist(vec3 p) // bounding box around scene
{
    // vec3 bo = p - vec3(5, 3, 4); // box origin

    float dBox1 = sdBox(p - vec3(2, 3, 4), vec3(.5, .5, 5)) - .1;
    float dBox2 = sdBox(p - vec3(5, 5, 4), vec3(.5, .5, 5)) - .1;
    return min(dBox1, dBox2); // signed distance function
}

float SceneDist(vec3 p) // complex scene sdf within bounding box
{
    return SceneBoxDist(p);
}

const mat2 wRot = mat2(cos(12.),sin(12.),-sin(12.),cos(12.));

vec3 srf(vec2 pos, int n)
{
    pos.y += iTime;
    // pos.x += iTime;
    pos *= W_DEPTH;
   
    float freq = 0.6;
    float t = W_SPEED*iTime;
    float weight = 1.0;
    float w = 0.0;
    vec2 dx = vec2(0);
    
    vec2 dir = vec2(1,0);
    for(int i=0;i<n;i++){
        dir = wRot*dir;
        float x = dot(dir, pos) * freq + t;
        float wave = exp(sin(x)-1.);
        vec2 res = vec2(wave, wave*cos(x)) * weight;
        pos    -= dir*res.y*.48;
        w      += res.x;
        dx     += res.y*dir / pow(weight,W_DETAIL);
        weight *= .8;
        freq   *= 1.2;
        t   *= 1.08;
    }
    float ws = (pow(.8,float(n))-1.)*-5.; //Geometric sum
    
    return -.15 * sin(pos.x * -.3 + pos.y - 2. * iTime) + vec3(w / ws,dx / pow(ws,1.-W_DETAIL));
}

vec3 norm(vec2 p, int n){
    return normalize(vec3(-srf(p.xy, n).yz, 1.).xzy);
}

float WaveHeight(vec3 p)
{
    return srf(p.xz, ITERS_RAY).x * .5;
}

float WaterDist(vec3 p)
{
    return p.y - WaveHeight(p * .5);
}

vec3 WaterNormal(vec3 p)
{
    // vec2 e = vec2(.001, 0);
    // vec3 n = WaterDist(p) - vec3(WaterDist(p-e.xyy),
    //                              WaterDist(p-e.yxy),
    //                              WaterDist(p-e.yyx));
    // return normalize(n);
    return norm(p.xz * .5, ITERS_NORMAL);
}

vec2 RayMarch(vec3 ro, vec3 rd)
{   
    float dOrigin = 0.;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dOrigin;
        float dSceneBox = SceneBoxDist(p);
        float dWater = WaterDist(p);
        float dObj = min(dSceneBox, dWater);
        dOrigin += dObj;
        
        if (abs(dObj) < SURF_DIST)
            return vec2(dOrigin, dSceneBox < dWater ? SCENE_BOX : WATER);
        
        if (dOrigin > MAX_DIST) 
            break;
    }

    return vec2(dOrigin, SKY);
}

// does not render scene reflections in water
vec2 SceneMarch(vec3 ro, vec3 rd)
{
    float dOrigin = 0.;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dOrigin;
        float dScene = SceneDist(p);
        dOrigin += dScene;
        
        if (abs(dScene) < SURF_DIST) // contact with real scene
            return vec2(dOrigin, SCENE);
        
        if (SceneBoxDist(p) < -SURF_DIST) // outside real scene bounding box
            return RayMarch(p, rd);
    }
    return vec2(MAX_DIST, SKY);
}

vec3 RenderReflection(vec3 ro, vec3 rd)
{
    vec2 march = RayMarch(ro, rd);
    float d = march.x;
    float obj = march.y;

    // if (obj == SCENE_BOX) { // get finer detailed sdf
    //     p = ro + rd * d;
    //     march = SceneMarch(p, rd);
    //     d = march.x;
    //     obj = march.y;
    // }
   

    // if (obj == WATER) {
    //     return RenderPixel(ro + rd * d, rd);
    // }
    if (obj == SCENE_BOX) {
        return sceneObjectColor;
    }
    else {
        return SkyColor(rd);
    }
}

vec3 RenderPixel(vec3 ro, vec3 rd)
{
    vec2 march = RayMarch(ro, rd);
    float d = march.x;
    float obj = march.y;
    vec3 p = vec3(0), col = vec3(0);

    // if (obj == SCENE_BOX) { // get finer detailed sdf
    //     p = ro + rd * d;
    //     march = SceneMarch(p, rd);
    //     d += march.x;
    //     obj = march.y;
    // }

    if (obj == WATER) {
        p = ro + rd * (d - SURF_DIST * 2.);
        vec3 n = WaterNormal(p);
        vec3 rfl = reflect(rd, n);
        vec3 rflColor = RenderReflection(p, rfl);
        vec3 wtrColor =  WaterColor(rflColor, ro, rd, p);
        return mix(wtrColor, SkyColor(rd), smoothstep(0., 100., d));
    }
    else if (obj == SCENE_BOX) {
        return sceneObjectColor;
    }
    else {
        return SkyColor(rd);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y; // scale to screen
    vec2 m = iMouse.xy / iResolution.xy; // scale mouse to screen

    vec3 ro_start = vec3(90, 6, 0);
    vec3 ro_begin = vec3(80, 8. + sin(iTime), 0);      // ray origin start of animation
    vec3 ro_stable = vec3(30, 5, 4);      // ray origin for 
    vec3 l = vec3(-1,2,0);                // ray look-at point

    // ray origin (animated)
    vec3 ro = ro_start + (ro_begin - ro_start) * smoothstep(0., 1., iTime);
    ro = ro + (ro_stable - ro) * smoothstep(.5, 5., iTime);

    //ro.yz *= Rot(-m.y * PI * 1.);   // rotate ray origin vertical
    ro.xz *= Rot(-m.x * TAU);       // rotate ray origin horizontal 
    ro.y = max(ro.y, 1.);

    vec3 rd = GetRayDir(uv, ro, l, 1.);   // ray direction for current pixel

    vec3 col = RenderPixel(ro, rd);
    vec2 d = pow(abs(uv*.5)+.1,vec2(4.));
	col *= pow(1.-.84*pow(d.x+d.y,.25),2.); //vignette
    col = pow(col,vec3(1./1.3)); // gamma correction

    fragColor = vec4(col, 1.0);
}