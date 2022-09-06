#define TAU 6.283185
#define PI 3.141592

#define MAX_STEPS 100
#define MAX_DIST_SCENE 100.
#define MAX_DIST_WATER 500.
#define MAX_DIST_DETAILED 10.
#define SURF_DIST 0.001

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

float sdBox(vec3 p, vec3 s)
{
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}
 
float SceneBoxDist(vec3 p) 
{
    vec3 co = p - vec3(5, 3, 4); // box origin
    return sdBox(co, vec3(.5, .5, 5)); // signed distance function
}

vec2 RayMarch(vec3 ro, vec3 rd)
{
	float dO=0.;
    

    vec2 collision = vec2(0); 
    
    for(int i=0; i< MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        collision.x = SceneBoxDist(p);
        dO += collision.x; // dist to collision
        if(dO > MAX_DIST)
            return vec2(dO, SKY);
            
        if (abs(collision.x) < SURF_DIST) 
            break;
    }
    
    return vec2(dO, collision.y);
}

float SceneDist(vec3 p)
{   
    float d = BoxDist(p); // minimum distance to the scene
    float d2 = sdBox(p - vec3(10, 5, 4), vec3(.5, .5, 5)); // signed distance function
    
    return min(d, d2);
}

float WaterDist(vec3 p)
{
    float h = sin(p.z + iTime) + cos(p.x + sin(iTime));
    h = h * .3 + .5;
    return p.y + h; // signed distance function of waves
}

vec3 WaterNormal(vec3 p)
{
    vec2 e = vec2(.001, 0);
    vec3 n = WaterDist(p) - vec3(WaterDist(p-e.xyy),
                                 WaterDist(p-e.yxy),
                                 WaterDist(p-e.yyx));
    return normalize(n);
}

float RayMarchWater(vec3 ro, vec3 rd)
{
    float d = 0.;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float delta = WaterDist(p);
        d = d + delta;
        if (d > MAX_DIST_WATER || abs(delta) < SURF_DIST) break;
    }
    return d;
}

float RayMarchScene(vec3 ro, vec3 rd)
{
    float d = 0.;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float delta = SceneDist(p);
        d = d + delta;
        if (d > MAX_DIST_SCENE) break;
        if (abs(delta) < SURF_DIST) return d;
    }
    return d;
}

vec3 SkyColor(vec3 rd)
{
    vec3 colSky = vec3(0.2, 0.1176, 0.6078);
    return colSky;
}

vec3 SceneColor(vec3 ro, vec3 rd, float dScene)
{
    if (dScene > MAX_DIST_SCENE) // sky hit
        return SkyColor(rd);
    
    vec3 colBox = vec3(0.8745, 0.1647, 0.1647);
    return colBox;
}

vec3 WaterColor(vec3 rflCol, vec3 ro, vec3 rd, float d)
{
    vec3 p = ro + rd * d;
    return .5 * rflCol + .2 * WaterNormal(p);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y; // scale to screen
    vec2 m = iMouse.xy / iResolution.xy; // scale mouse to screen

    vec3 ro = vec3(30, 10, 0);      // ray origin
    vec3 l = vec3(-1,2,0);          // ray look-at point
    ro.yz *= Rot(-m.y * PI * 1.);   // rotate vertical
    ro.xz *= Rot(-m.x * TAU);       // rotate horizontal 

    vec3 rd = GetRayDir(uv, ro, l, 1.);   // ray direction for current pixel

    float dScene = RayMarchScene(ro, rd); // distance to scene
    float dWater = RayMarchWater(ro, rd); // distance to water

    vec3 col = vec3(0);

    if (dScene < dWater && dScene < MAX_DIST_SCENE) { // scene hit
        col = SceneColor(ro, rd, dScene);
    } 
    else if (dWater < dScene && dWater < MAX_DIST_WATER) { // water hit
        vec3 rflo = ro + rd * dWater;           // reflection ray origin
        vec3 n = WaterNormal(rflo);             // wave normal at ray origin
        vec3 rfld = reflect(rd, n);             // reflection ray direction
        dScene = RayMarchScene(rflo, rfld);     // distance from water to scene
        vec3 colScene = SceneColor(rflo, rfld, dScene); // reflection color
        col = WaterColor(colScene, ro, rd, dWater);     // water color
    } 
    else { // sky hit
        col = SkyColor(rd);
    }

    fragColor = vec4(col, 1.);
    return;
}