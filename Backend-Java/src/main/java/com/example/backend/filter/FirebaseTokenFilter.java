package com.example.backend.filter;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

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

        String token = header.substring(7);
        try {
            FirebaseToken decodedToken = firebaseAuth.verifyIdToken(token);
            if (decodedToken != null) {
                List<GrantedAuthority> authorities = new ArrayList<>();

                // Check for role in custom claims first
                String role = (String) decodedToken.getClaims().get("role");

                if (role != null && !role.isEmpty()) {
                    authorities.add(new SimpleGrantedAuthority(role));
                } else {
                    // Fallback to Firestore if no claim is present
                    String uid = decodedToken.getUid();
                    String institutionId = null;

                    // Strategy 1: Try to extract from URL path like /{institutionId}/api/...
                    String requestURI = request.getRequestURI();
                    String[] pathParts = requestURI.split("/");
                    if (pathParts.length > 2 && "api".equals(pathParts[2])) {
                        institutionId = pathParts[1];
                    }

                    // Strategy 2: If not found in path, try to get from request parameter
                    if (institutionId == null || institutionId.isEmpty()) {
                        institutionId = request.getParameter("institutionId");
                    }
                    
                    log.info("Attempting to get role from Firestore for UID: {} in Institution: {}", uid, institutionId);

                    if (uid != null && institutionId != null && !institutionId.isEmpty()) {
                        DocumentSnapshot userDoc = firestore.collection("Institutions").document(institutionId).collection("users").document(uid).get().get();
                        if (userDoc.exists() && userDoc.contains("role")) {
                            String firestoreRole = userDoc.getString("role");
                            if (firestoreRole != null) {
                                authorities.add(new SimpleGrantedAuthority(firestoreRole));
                                log.info("Found role '{}' in Firestore for user {}", firestoreRole, uid);
                            }
                        } else {
                            log.warn("Could not find user document or role in Firestore for UID: {}", uid);
                        }
                    } else {
                        log.warn("Could not determine institutionId from request to perform role lookup for UID: {}", uid);
                    }
                }
                
                log.info("Final granted authorities for {}: {}", decodedToken.getUid(), authorities);

                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        decodedToken, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (Exception e) {
            // Invalid token or Firestore error
            log.error("Error verifying Firebase token: {}", e.getMessage());
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
