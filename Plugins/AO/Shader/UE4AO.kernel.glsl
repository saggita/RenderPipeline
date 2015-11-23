

/*

UE4AO - Unreal Engine 4 AO

This is an ambient occlusion technique proposed by Unreal Engine. It is very
similar to Alchemy AO, but uses paired samples to approximate the average
unocluded vector. 

*/

const float sample_radius = GET_SETTING(AO, ue4ao_sample_radius);
const int num_samples = GET_SETTING(AO, ue4ao_sample_count);
const float max_distance = GET_SETTING(AO, ue4ao_max_distance);

float accum = 0.0;
float accum_count = 0.0;


for (int i = 0; i < num_samples; ++i) {
    
    vec2 offset = poisson_disk_2D_32[i] + noise_vec.xy * 0.3;
    vec2 offcoord = offset * pixel_size * sample_radius * kernel_scale * 0.5;

    // Get offset coordinates
    vec2 texc_a = texcoord + offcoord;
    vec2 texc_b = texcoord - offcoord;

    // Get view position at that offsets
    vec3 off_pos_a = get_view_pos_at(texc_a);
    vec3 off_pos_b = get_view_pos_at(texc_b);

    // Get the vector s-p to that sample positions
    vec3 sample_vec_a = normalize(off_pos_a - pixel_view_pos);
    vec3 sample_vec_b = normalize(off_pos_b - pixel_view_pos);

    // Get distances
    float dist_a = distance(off_pos_a, pixel_view_pos) / max_distance;
    float dist_b = distance(off_pos_b, pixel_view_pos) / max_distance;

    // Check if the samples are valid
    float valid_a = step(dist_a - 1, 0.0); 
    float valid_b = step(dist_b - 1, 0.0); 

    float angle_a = max(0, dot(sample_vec_a, pixel_view_normal));
    float angle_b = max(0, dot(sample_vec_b, pixel_view_normal));

    if (valid_a != valid_b) {
        angle_a = mix(-angle_b, angle_a, valid_a);
        angle_b = mix(angle_a, -angle_b, valid_b);
        dist_a = mix(dist_b, dist_a, valid_a);
        dist_b = mix(dist_a, dist_b, valid_b);
    }

    // In case any sample is valid
    if (valid_a > 0.5 || valid_b > 0.5) {

        accum += (angle_a+angle_b) * 0.25 * (2 - (dist_a+dist_b));
        accum_count += 1.0;

    } else {
        accum_count += 0.5;

    }


}
// accum /= num_samples;
accum /= max(1.0, accum_count);

// Bent normal not supported yet
vec3 bent_normal = pixel_world_normal;

result = vec4(bent_normal, 1 - saturate(accum));
