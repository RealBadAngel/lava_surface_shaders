uniform sampler2D baseTexture;
uniform sampler2D normalTexture;
uniform sampler2D textureFlags;
uniform sampler2D specialTexture;

uniform vec4 skyBgColor;
uniform float fogDistance;
uniform vec3 eyePosition;
uniform float animationTimer;

varying vec3 vPosition;
varying vec3 worldPosition;

varying vec3 eyeVec;
varying vec3 tsEyeVec;
varying vec3 lightVec;
varying vec3 tsLightVec;

varying vec3 normal;
varying vec3 binormal;
varying vec3 tangent;

bool normalTexturePresent = false;
bool texTileableHorizontal = false;
bool texTileableVertical = false;
bool texSeamless = false;

const float e = 2.718281828459;
const float BS = 10.0;

void get_texture_flags()
{
	vec4 flags = texture2D(textureFlags, vec2(0.0, 0.0));
	if (flags.r > 0.5) {
		normalTexturePresent = true;
	}
	if (flags.g > 0.5) {
		texTileableHorizontal = true;
	}
	if (flags.b > 0.5) {
		texTileableVertical = true;
	}
	if (texTileableHorizontal && texTileableVertical) {
		texSeamless = true;
	}
}

float intensity(vec3 color)
{
	return (color.r + color.g + color.b) / 3.0;
}

float get_rgb_height(vec2 uv)
{
	return intensity(texture2D(baseTexture,uv).rgb);
}

vec4 get_normal_map(vec2 uv)
{
	vec4 bump = texture2D(normalTexture, uv).rgba;
	bump.xyz = normalize(bump.xyz * 2.0 -1.0);
	bump.y = -bump.y;
	return bump;
}

float find_intersection(vec2 dp, vec2 ds)
{
	const float depth_step = 1.0 / 20.0;
	float depth = 1.0;
	for (int i = 0 ; i < 20 ; i++) {
		float h = texture2D(normalTexture, dp + ds * depth).a;
		if (h >= depth)
			break;
		depth -= depth_step;
	}
	return depth;
}

void main(void)
{
	vec2 windDir = vec2(0.0, 0.0); //wind direction XY
	float x,y,z;
	x = worldPosition.x / 16.0;
	y = worldPosition.y / 32.0;
	z = worldPosition.z / 16.0;
	vec2 uv = vec2 (x + y, z - y);
	/*
	float timer = animationTimer * 50.0;
	if (normal.x == 0.0 && normal.z == 0.0) 
		windDir = 0.7 * normalize(vec2(-binormal.x, -binormal.z));
	else if (binormal.x == 0.0 && binormal.z == 0.0)
		windDir = vec2 (4.5, -4.5);
	else 
		windDir = 4.5 * normalize(vec2(binormal.x, binormal.z));
	*/
	vec4 noise = texture2D(specialTexture, uv);
	vec2 T1 = uv + vec2(1.5, -1.5) * animationTimer * 2.5;
	vec2 T2 = uv + vec2(-0.5, 2.0) * animationTimer * 0.5;
	T1.x += noise.x * 1.5;
	T1.y += noise.y * 1.5;
	T2.x -= noise.y * 0.5;
	T2.y += noise.z * 0.5;
	//T2= uv;
	
	vec2 eyeRay = vec2 (tsEyeVec.x, tsEyeVec.y);
	vec2 ds = eyeRay * 0.10;
	float dist = find_intersection(T2, ds);
	T2 += dist * ds;
	T1 += dist * ds;

	float p = texture2D(specialTexture, T1 * 2.0).a;
	vec4 color = texture2D(baseTexture, T2);
	vec4 bump = normalize(texture2D(normalTexture, T2) * 2.0 - 1.0);
	vec4 temp = color * (vec4(p, p, p, p) * 1.8) + (color * color - 0.2);
	if (temp.r > 1.0) {
		temp.bg += clamp(temp.r - 2.0, 0.0, 1.0);
	}
	if (temp.g > 1.0) {
		temp.rb += temp.g - 1.0;
	}
	if (temp.b > 1.0) {
		temp.rg += temp.b - 1.0;
	}
	temp = clamp(temp, 0.0, 1.0);
	vec3 L = normalize(lightVec);
	vec3 E = normalize(eyeVec);
	float specular = pow(clamp(dot(reflect(L, bump.xyz), E), 0.0, 1.0), 1.0);
	float diffuse = dot(-E,bump.xyz);
	vec4 col = vec4((0.1 + diffuse) * temp.rgb, 1.0);

	col *= gl_Color;
	if(fogDistance != 0.0){
		float d = max(0.0, min(vPosition.z / fogDistance * 1.5 - 0.6, 1.0));
		col = mix(col, skyBgColor, d);
	}
	gl_FragColor = vec4(col.rgba);
}
