vec3 palette( float t ) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);
    return a + b*cos( 6.28318*(c*t+d) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy / iResolution.xy) * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    float r = length(uv);
    float core = exp(-5.0 * r); 
    core = pow(core, 0.8);
    core *= 0.6 + 0.1*sin(10.0*r - iTime*2.0);
    
    float a = atan(uv.y, uv.x);
    
    float numStrands = 8.0; 
    
    float spiral = r * 5.0 - iTime * 2.0;
    float strandAngle = a * numStrands + spiral;
    
    float majorWave = sin(iTime * 1.5 + r * 6.0 + a * 2.0) * 0.6;
    float minorWave = sin(iTime * 2.3 + r * 8.0 + a * 4.0) * 0.4;
    strandAngle += majorWave + minorWave;
    
    float branchFreq = 5.0;
    float branchPhase = sin(iTime * 1.2 + r * 4.0);
    float branchEffect = sin(strandAngle * branchFreq + branchPhase * 3.14159) * 
                        exp(-2.0 * abs(sin(r * 2.0 - iTime * 0.5))) * 0.8;
    strandAngle += branchEffect;
    
    float bands = sin(strandAngle);
    bands = smoothstep(0.7, 0.95, bands);
    
    float thinBands = sin(strandAngle * 2.0 + 1.57);
    thinBands = smoothstep(0.9, 0.98, thinBands) * 0.3;
    bands = max(bands, thinBands);
    
    float colorInput = (a + spiral * 0.1) / 6.28318 + iTime * 0.15 + r * 0.3 + branchEffect * 0.2;
    vec3 bandColor = palette(colorInput);
    
    vec3 col;
    col.r = exp(-15.0*length(uv*1.0 + 0.01*sin(iTime+0.0)));
    col.g = exp(-15.0*length(uv*1.0 + 0.01*sin(iTime+2.0)));
    col.b = exp(-15.0*length(uv*1.0 + 0.01*sin(iTime+4.0)));
    
    col += vec3(1.0) * core * 1.0;
    col += bandColor * bands * exp(-2.0*r);
    
    fragColor = vec4(col, 1.0);
}
