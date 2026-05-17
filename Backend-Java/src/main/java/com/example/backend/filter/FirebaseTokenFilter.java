package com.example.backend.filter;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class FirebaseTokenFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(FirebaseTokenFilter.class);
    private final FirebaseAuth firebaseAuth;
    private final Firestore firestore;

    public FirebaseTokenFilter(FirebaseAuth firebaseAuth, Firestore firestore) {
        this.firebaseAuth = firebaseAuth;
        this.firestore = firestore;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String header = request.getHeader("Authorization");

        if (header == null || !header.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String tokenString = header.substring(7);
        try {
            FirebaseToken decodedToken = firebaseAuth.verifyIdToken(tokenString);
            if (decodedToken != null) {
                List<GrantedAuthority> authorities = new ArrayList<>();
                String role = (String) decodedToken.getClaims().get("role");
                
                if (role == null) {
                    log.warn("Role claim missing for user: {}. Falling back to Firestore lookup.", decodedToken.getUid());
                    
                    // Fallback 1: Try common institution paths (RVU is likely based on your URL)
                    String[] possibleInstitutions = {"RVU", "demo", "test"};
                    for (String instId : possibleInstitutions) {
                        try {
                            DocumentSnapshot userDoc = firestore.collection("Institutions").document(instId)
                                    .collection("users").document(decodedToken.getUid()).get().get();
                            if (userDoc.exists()) {
                                role = userDoc.getString("role");
                                log.info("Found role '{}' in Institutions/{}/users/{}", role, instId, decodedToken.getUid());
                                break;
                            }
                        } catch (Exception e) { /* ignore */ }
                    }

                    // Fallback 2: Collection Group (requires index)
                    if (role == null) {
                        try {
                            QuerySnapshot querySnapshot = firestore.collectionGroup("users")
                                    .whereEqualTo("email", decodedToken.getEmail())
                                    .limit(1).get().get();
                            if (!querySnapshot.isEmpty()) {
                                role = querySnapshot.getDocuments().get(0).getString("role");
                                log.info("Found role '{}' via collectionGroup for email {}", role, decodedToken.getEmail());
                            }
                        } catch (Exception e) {
                            log.error("CollectionGroup 'users' failed (index might be missing): {}", e.getMessage());
                        }
                    }

                    // If found, sync it back to Firebase for the FUTURE
                    if (role != null) {
                        Map<String, Object> claims = new HashMap<>();
                        claims.put("role", role);
                        firebaseAuth.setCustomUserClaims(decodedToken.getUid(), claims);
                        log.info("Synced custom claims for user {}", decodedToken.getUid());
                    } else {
                        log.error("CRITICAL: Could not find user {} in Firestore. No role assigned.", decodedToken.getUid());
                    }
                }

                if (role != null) {
                    // Normalize role and add ROLE_ prefix for Spring Security hasRole() to work
                    authorities.add(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()));
                }

                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        decodedToken.getUid(), null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (Exception e) {
            log.error("Error verifying Firebase token: {}", e.getMessage());
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
