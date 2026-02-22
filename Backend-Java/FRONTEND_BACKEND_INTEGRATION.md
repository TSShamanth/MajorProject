# Announcements Feature - Frontend to Backend Integration Guide

## Overview
This document explains how the Flutter frontend connects to the Java Spring Boot backend for the announcements feature.

## API Service Integration

The frontend uses the `AnnouncementService` class (in `lib/services/announcement_service.dart`) to communicate with backend endpoints.

### Base URL Configuration
```dart
String baseUrl = 'http://your-backend-url.com/api';
String institutionId = 'RVU'; // From SessionManager
```

### Authentication
All requests include Firebase JWT tokens:
```dart
String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

## Endpoint Mappings

### 1. Get All Announcements
**Frontend:**
```dart
Future<List<Announcement>> getAnnouncements() async {
  final response = await http.get(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements'),
  );
  // Parse and return announcements
}
```

**Backend:**
```
GET /api/institutions/{institutionId}/announcements
Response: List[Announcement] sorted by pinned+date
Auth: None required (public)
```

### 2. Create Announcement
**Frontend:**
```dart
Future<void> createAnnouncement(Announcement announcement) async {
  final response = await http.post(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements'),
    headers: {...headers, Authorization},
    body: jsonEncode(announcement.toJson()),
  );
}
```

**Backend:**
```
POST /api/institutions/{institutionId}/announcements
Headers: Authorization: Bearer {token}
Body: Announcement JSON object
Returns: Created Announcement with ID and timestamps
Auth: Required (admin/faculty)
```

**Announcement JSON Structure:**
```json
{
  "title": "Semester Results Released",
  "description": "Results now available",
  "content": "Full announcement content here...",
  "priority": "HIGH",
  "category": "ACADEMIC",
  "status": "PUBLISHED",
  "targetAudience": ["STUDENTS"],
  "targetDepartments": [],
  "scheduledFor": 0,
  "attachmentUrls": ["https://example.com/file.pdf"]
}
```

### 3. Get Announcement by ID
**Frontend:**
```dart
Future<Announcement?> getAnnouncementById(String announcementId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements/$announcementId'),
  );
}
```

**Backend:**
```
GET /api/institutions/{institutionId}/announcements/{announcementId}
Returns: Single Announcement object
Auth: None required (public)
```

### 4. Update Announcement
**Frontend:**
```dart
Future<void> updateAnnouncement(Announcement announcement) async {
  final response = await http.put(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements/${announcement.id}'),
    headers: {...headers, Authorization},
    body: jsonEncode(announcement.toJson()),
  );
}
```

**Backend:**
```
PUT /api/institutions/{institutionId}/announcements/{announcementId}
Headers: Authorization: Bearer {token}
Body: Updated Announcement JSON
Returns: Updated Announcement
Auth: Required (creator only)
```

### 5. Delete Announcement
**Frontend:**
```dart
Future<void> deleteAnnouncement(String announcementId) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements/$announcementId'),
    headers: {...headers, Authorization},
  );
}
```

**Backend:**
```
DELETE /api/institutions/{institutionId}/announcements/{announcementId}
Headers: Authorization: Bearer {token}
Returns: Success message
Auth: Required (creator only)
```

### 6. Search Announcements
**Frontend:**
```dart
Future<List<Announcement>> searchAnnouncements(String query) async {
  final response = await http.get(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements/search?q=$query'),
  );
}
```

**Backend:**
```
GET /api/institutions/{institutionId}/announcements/search?q=search_term
Returns: List[Announcement] matching search query
Auth: None required (public)
```

### 7. Get by Category
**Frontend:**
```dart
final response = await http.get(
  Uri.parse('$baseUrl/institutions/$_institutionId/announcements/category/$category'),
);
```

**Backend:**
```
GET /api/institutions/{institutionId}/announcements/category/{category}
Categories: ACADEMIC, ADMINISTRATIVE, PLACEMENT, EVENT, OTHER
Returns: List[Announcement] in category
Auth: None required (public)
```

### 8. Get by Priority
**Frontend:**
```dart
final response = await http.get(
  Uri.parse('$baseUrl/institutions/$_institutionId/announcements/priority/$priority'),
);
```

**Backend:**
```
GET /api/institutions/{institutionId}/announcements/priority/{priority}
Priorities: HIGH, MEDIUM, LOW
Returns: List[Announcement] with priority
Auth: None required (public)
```

### 9. Mark as Viewed
**Frontend:**
```dart
Future<void> markAnnouncementAsViewed(String announcementId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements/$announcementId/view'),
    headers: {...headers, Authorization},
  );
}
```

**Backend:**
```
POST /api/institutions/{institutionId}/announcements/{announcementId}/view
Headers: Authorization: Bearer {token}
Returns: Success message
Effect: Increments viewCount, adds viewer info with timestamp
Auth: Required
```

### 10. My Announcements (Management)
**Frontend:**
```dart
Future<List<Announcement>> getMyAnnouncements() async {
  final response = await http.get(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements/manage/my-announcements'),
    headers: {...headers, Authorization},
  );
}
```

**Backend:**
```
GET /api/institutions/{institutionId}/announcements/manage/my-announcements
Headers: Authorization: Bearer {token}
Returns: List[Announcement] created by current user (all statuses)
Auth: Required
```

### 11. All Announcements (Management)
**Frontend:**
```dart
Future<List<Announcement>> getAllAnnouncementsForManagement() async {
  final response = await http.get(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements/manage/all'),
    headers: {...headers, Authorization},
  );
}
```

**Backend:**
```
GET /api/institutions/{institutionId}/announcements/manage/all
Headers: Authorization: Bearer {token}
Returns: List[Announcement] all (drafts, published, archived)
Auth: Required (admin)
```

### 12. Toggle Pin Status
**Frontend:**
```dart
Future<void> togglePinStatus(String announcementId, bool isPinned) async {
  final response = await http.post(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements/$announcementId/toggle-pin?isPinned=$isPinned'),
    headers: {...headers, Authorization},
  );
}
```

**Backend:**
```
POST /api/institutions/{institutionId}/announcements/{announcementId}/toggle-pin?isPinned=true|false
Headers: Authorization: Bearer {token}
Returns: Success message
Auth: Required
```

### 13. Get Announcements by Audience
**Frontend:**
```dart
Future<List<Announcement>> getAnnouncementsForAudience(
  String userRole,
  String departmentId,
) async {
  final response = await http.get(
    Uri.parse('$baseUrl/institutions/$_institutionId/announcements/audience?userRole=$userRole&departmentId=$departmentId'),
    headers: {...headers, Authorization},
  );
}
```

**Backend:**
```
GET /api/institutions/{institutionId}/announcements/audience?userRole=STUDENTS&departmentId=dept-id
Headers: Authorization: Bearer {token}
Returns: List[Announcement] filtered by audience
Auth: Required
```

## Data Model Synchronization

### Frontend Model (announcement_model.dart)
```dart
class Announcement {
  String id;
  String title;
  String description;
  String content;
  String createdBy;
  String creatorName;
  String creatorPhotoUrl;
  DateTime createdAt;
  DateTime updatedAt;
  String priority;
  String category;
  String status;
  List<String> targetAudience;
  List<String> targetDepartments;
  DateTime? scheduledFor;
  List<String> attachmentUrls;
  int viewCount;
  bool isPinned;
}
```

### Backend Model (Announcement.java)
```java
public class Announcement {
  String id;
  String institutionId;
  String title;
  String description;
  String content;
  String createdBy;
  String creatorName;
  String creatorPhotoUrl;
  long createdAt;           // timestamp in milliseconds
  long updatedAt;           // timestamp in milliseconds
  String priority;
  String category;
  String status;
  List<String> targetAudience;
  List<String> targetDepartments;
  long scheduledFor;        // timestamp in milliseconds
  List<String> attachmentUrls;
  int viewCount;
  List<Map<String, Object>> viewers;  // [{uid, viewedAt}, ...]
  boolean isPinned;
}
```

**Note**: Frontend uses `DateTime` while backend uses `long` (milliseconds since epoch). Ensure proper conversion during serialization/deserialization.

## Error Handling

### Frontend Error Mapping
```dart
class AnnouncementService {
  Future<void> _handleError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        throw FormatException('Invalid input');
      case 401:
        throw UnauthorizedException('Not authenticated');
      case 403:
        throw ForbiddenException('Not authorized to perform this action');
      case 404:
        throw NotFoundException('Announcement not found');
      case 500:
        throw ServerException('Server error occurred');
    }
  }
}
```

### Backend Error Responses
```json
{
  "error": "Error message describing the problem"
}
```

## Environment Configuration

### Backend Configuration (application.properties)
```properties
# Firebase Configuration
firebase.service-account-key=path/to/service-account-key.json

# Server Configuration
server.port=8080
server.servlet.context-path=/

# CORS Configuration
cors.allowed-origins=*
cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS
cors.allowed-headers=*
```

### Frontend Configuration (lib/config/api_config.dart)
```dart
class ApiConfig {
  static const String baseUrl = 'http://your-backend-url.com/api';
  static const Duration timeout = Duration(seconds: 30);
}
```

## Testing the Integration

### Test 1: Create and retrieve announcement
```bash
# 1. Start backend server
# 2. Get Firebase token from Flutter app (debug console or Logcat)
# 3. Create announcement:
curl -X POST http://localhost:8080/api/institutions/RVU/announcements \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Test","content":"Test","priority":"HIGH","category":"ACADEMIC","status":"PUBLISHED","targetAudience":["ALL"],"targetDepartments":[],"scheduledFor":0,"attachmentUrls":[]}'

# 4. Get announcements in Flutter app
# 5. Verify announcement appears in list
```

### Test 2: View tracking
```bash
# Get token, create announcement
# Mark as viewed:
curl -X POST http://localhost:8080/api/institutions/RVU/announcements/{id}/view \
  -H "Authorization: Bearer $TOKEN"

# Verify in Firebase Console:
# - viewCount incremented
# - viewers array contains user entry
```

### Test 3: Permission validation
```bash
# As User A:
# 1. Create announcement
# 2. Get announcement ID
# 3. Try to delete from User B account (should fail with 403)
curl -X DELETE http://localhost:8080/api/institutions/RVU/announcements/{id} \
  -H "Authorization: Bearer $USER_B_TOKEN"
# Expected: 403 Forbidden
```

## Deployment Checklist

- [ ] Backend environment variables configured
- [ ] Firebase service account key placed correctly
- [ ] Firestore security rules implemented
- [ ] Frontend API base URL points to production backend
- [ ] CORS configuration includes frontend domain
- [ ] Database indexes created in Firestore
- [ ] Rate limiting configured (if needed)
- [ ] Error logging system enabled
- [ ] Notification system configured (if using)
- [ ] Backup strategy implemented
- [ ] Load testing completed
- [ ] SSL/HTTPS enabled for production

## Support & Debugging

1. **403 Forbidden on update/delete**: Ensure you're the creator or admin
2. **401 Unauthorized**: Check Firebase token validity and refresh if needed
3. **500 Server Error**: Check backend logs for detailed error messages
4. **Empty results**: Ensure:
   - Announcement status is "PUBLISHED" (for public endpoints)
   - Institution ID matches
   - User has permission to view
5. **Network timeout**: Increase timeout in frontend or check backend connectivity

---

**Last Updated**: 2026-02-17
