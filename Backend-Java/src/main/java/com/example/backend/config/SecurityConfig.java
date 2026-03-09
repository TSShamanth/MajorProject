package com.example.backend.config;

import com.example.backend.filter.FirebaseTokenFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;

import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    private final FirebaseTokenFilter firebaseTokenFilter;

    public SecurityConfig(FirebaseTokenFilter firebaseTokenFilter) {
        this.firebaseTokenFilter = firebaseTokenFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource())) // Enable CORS
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(authz -> authz
                    // Let method-level security (@PreAuthorize) handle role checks.
                    // This level just ensures the user is authenticated for these paths.
                    .requestMatchers(
                        new AntPathRequestMatcher("/api/institutions/*/forms/**"),
                        new AntPathRequestMatcher("/api/institutions/*/forms")
                    ).permitAll()
                    .requestMatchers(
                        new AntPathRequestMatcher("/api/admin/**"),
                        new AntPathRequestMatcher("/*/api/admin/**"),
                        new AntPathRequestMatcher("/api/attendance/**"),
                        new AntPathRequestMatcher("/*/api/attendance/**"),
                        new AntPathRequestMatcher("/api/users/**"),
                        new AntPathRequestMatcher("/*/api/users/**"),
                        new AntPathRequestMatcher("/api/fees/**"),
                        new AntPathRequestMatcher("/*/api/fees/**"),
                        new AntPathRequestMatcher("/api/institutions/**"),
                        new AntPathRequestMatcher("/*/api/institutions/**"),
                        new AntPathRequestMatcher("/api/faculty/**"),
                        new AntPathRequestMatcher("/*/api/faculty/**"),
                        new AntPathRequestMatcher("/api/regularisation/**"),
                        new AntPathRequestMatcher("/*/api/regularisation/**")
                    ).authenticated()
                    .anyRequest().permitAll()
                )
                .addFilterBefore(firebaseTokenFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
