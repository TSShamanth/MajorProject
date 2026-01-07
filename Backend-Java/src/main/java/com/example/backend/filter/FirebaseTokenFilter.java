package com.example.backend.filter;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class FirebaseTokenFilter extends OncePerRequestFilter {

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
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
            if (decodedToken != null) {
                List<GrantedAuthority> authorities = new ArrayList<>();

                // Check for role in custom claims first
                String role = (String) decodedToken.getClaims().get("role");

                if (role != null && !role.isEmpty()) {
                    authorities.add(new SimpleGrantedAuthority(role));
                } else {
                    // Fallback to Firestore if no claim is present
                    Firestore db = FirestoreClient.getFirestore();
                    DocumentSnapshot userDoc = db.collection("users").document(decodedToken.getUid()).get().get();
                    if (userDoc.exists() && userDoc.contains("role")) {
                        String firestoreRole = userDoc.getString("role");
                        if (firestoreRole != null) {
                            authorities.add(new SimpleGrantedAuthority(firestoreRole));
                        }
                    }
                }
                
                System.out.println("✅ Granting authorities: " + authorities);

                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        decodedToken, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (Exception e) {
            // Invalid token or Firestore error
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
