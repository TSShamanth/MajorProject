# Announcements Feature - Backend Implementation

## Overview
This document describes the backend implementation of the announcements feature for the Acadexa platform. The backend handles all API operations for creating, managing, viewing, and searching announcements with proper authentication and authorization.

## Architecture

### Technology Stack
- **Framework**: Spring Boot 3.2.0
- **Language**: Java 21
- **Database**: Google Cloud Firestore
- **Authentication**: Firebase Authentication with JWT tokens
- **Security**: Spring Security

### Project Structure
```
src/main/java/com/example/backend/
├── models/
│   └── Announcement.java          # Core announcement data model
├── service/
│   └── AnnouncementService.java   # Business logic for announcements
├── controller/
│   └── AnnouncementController.java # REST API endpoints
├── dto/
│   └── CreateAnnouncementRequest.java # Request validation DTO
└── config/
    └── SecurityConfig.java        # Updated with announcement endpoints
```

## Data Model

### Announcement Entity
Located in `models/Announcement.java`

**Fields:**
- `id` (String): Unique identifier (auto-generated UUID)
- `institutionId` (String): Institution identifier
- `title` (String): Announcement title
- `description` (String): Brief description/summary
- `content` (String): Full announcement content
- `createdBy` (String): UID of announcement creator
- `creatorName` (String): Name of creator (for display)
- `creatorPhotoUrl` (String): Photo URL of creator
- `createdAt` (long): Creation timestamp (milliseconds)
- `updatedAt` (long): Last update timestamp
- `priority` (String): HIGH, MEDIUM, LOW
- `category` (String): ACADEMIC, ADMINISTRATIVE, PLACEMENT, EVENT, OTHER
- `status` (String): DRAFT, PUBLISHED, ARCHIVED
- `targetAudience` (List<String>): ALL, STUDENTS, FACULTY, ADMIN, ALUMNI
- `targetDepartments` (List<String>): Department IDs for targeted announcements
- `scheduledFor` (long): Scheduled publish time (0 = immediate)
- `attachmentUrls` (List<String>): URLs to attachments
- `viewCount` (int): Number of users who viewed
- `viewers` (List<Map>): [{uid, viewedAt}] - tracking who viewed
- `isPinned` (boolean): Whether announcement is pinned to top

**Firestore Collection Path:**
```
Institutions/{institutionId}/announcements/{announcementId}
```

## Service Layer

### AnnouncementService (`service/AnnouncementService.java`)

**Core Methods:**

1. **createAnnouncement(Announcement, institutionId)**
   - Creates new announcement
   - Generates UUID
   - Sets timestamps
   - Returns created announcement

2. **getAnnouncements(institutionId)**
   - Retrieves all published announcements
   - Order: Pinned first, then by creation date (newest first)
   - Public endpoints use this

3. **getAnnouncementById(institutionId, announcementId)**
   - Fetches specific announcement
   - Returns null if not found

4. **updateAnnouncement(institutionId, announcementId, Announcement)**
   - Updates announcement (preserves creation info)
   - Sets updatedAt timestamp
   - Validates existence

5. **deleteAnnouncement(institutionId, announcementId)**
   - Permanently deletes announcement

6. **getMyAnnouncements(institutionId, userId)**
   - Gets announcements created by specific user
   - For admin/faculty management

7. **getAllAnnouncementsForManagement(institutionId)**
   - Gets all announcements (draft, published, archived)
   - For admin dashboard management

8. **markAnnouncementAsViewed(institutionId, announcementId, userId)**
   - Tracks who viewed announcement
   - Increments viewCount
   - Stores viewer info with timestamp

9. **searchAnnouncements(institutionId, searchQuery)**
   - Full-text search in title, description, content
   - Case-insensitive matching

10. **togglePinStatus(institutionId, announcementId, isPinned)**
    - Pin/unpin announcement to top

11. **getAnnouncementsForAudience(institutionId, userRole, departmentId)**
    - Filters announcements by target audience
    - Handles department-specific filtering

## API Endpoints

### Base URL
```
/api/institutions/{institutionId}/announcements
```

### Public Endpoints (No Authentication Required)

#### GET all announcements
```
GET /api/institutions/{institutionId}/announcements
Response: List[Announcement]
```

#### GET by category
```
GET /api/institutions/{institutionId}/announcements/category/{category}
Path Params: category (ACADEMIC, ADMINISTRATIVE, PLACEMENT, EVENT, OTHER)
Response: List[Announcement]
```

#### GET by priority
```
GET /api/institutions/{institutionId}/announcements/priority/{priority}
Path Params: priority (HIGH, MEDIUM, LOW)
Response: List[Announcement]
```

#### GET specific announcement
```
GET /api/institutions/{institutionId}/announcements/{announcementId}
Response: Announcement
```

#### Search announcements
```
GET /api/institutions/{institutionId}/announcements/search?q=search_term
Query Params: q (search query string)
Response: List[Announcement]
```

### Protected Endpoints (Authentication Required)

#### POST - Create announcement
```
POST /api/institutions/{institutionId}/announcements
Headers: Authorization: Bearer {token}
Body: {
  "title": "string",
  "description": "string",
  "content": "string",
  "priority": "HIGH|MEDIUM|LOW",
  "category": "ACADEMIC|ADMINISTRATIVE|PLACEMENT|EVENT|OTHER",
  "status": "DRAFT|PUBLISHED",
  "targetAudience": ["ALL|STUDENTS|FACULTY|ADMIN|ALUMNI"],
  "targetDepartments": ["dept-id-1", "dept-id-2"],
  "scheduledFor": 0,
  "attachmentUrls": ["url1", "url2"]
}
Response: Announcement (with generated id, timestamps)
Status: 201 Created | 401 Unauthorized | 500 Error
```

#### PUT - Update announcement
```
PUT /api/institutions/{institutionId}/announcements/{announcementId}
Headers: Authorization: Bearer {token}
Body: {announcement properties to update}
Response: Updated Announcement
Status: 200 OK | 401 Unauthorized | 403 Forbidden (not creator) | 404 Not Found | 500 Error
```

#### DELETE - Delete announcement
```
DELETE /api/institutions/{institutionId}/announcements/{announcementId}
Headers: Authorization: Bearer {token}
Response: Success message
Status: 200 OK | 401 Unauthorized | 403 Forbidden | 404 Not Found | 500 Error
```

#### POST - Mark as viewed
```
POST /api/institutions/{institutionId}/announcements/{announcementId}/view
Headers: Authorization: Bearer {token}
Response: Success message
Status: 200 OK | 401 Unauthorized | 404 Not Found | 500 Error
```

#### POST - Toggle pin status
```
POST /api/institutions/{institutionId}/announcements/{announcementId}/toggle-pin
Headers: Authorization: Bearer {token}
Query Params: isPinned=true|false
Response: Success message
Status: 200 OK | 401 Unauthorized | 500 Error
```

#### GET - My announcements (admin/faculty)
```
GET /api/institutions/{institutionId}/announcements/manage/my-announcements
Headers: Authorization: Bearer {token}
Response: List[Announcement] created by user
Status: 200 OK | 401 Unauthorized | 500 Error
```

#### GET - All announcements for management
```
GET /api/institutions/{institutionId}/announcements/manage/all
Headers: Authorization: Bearer {token}
Response: List[Announcement] (all drafts, published, archived)
Status: 200 OK | 401 Unauthorized | 500 Error
```

#### GET - Announcements for user's audience
```
GET /api/institutions/{institutionId}/announcements/audience?userRole=STUDENTS&departmentId=dept-id
Headers: Authorization: Bearer {token}
Query Params: userRole (STUDENTS, FACULTY, ADMIN, ALUMNI), departmentId (optional)
Response: List[Announcement] filtered by audience
Status: 200 OK | 401 Unauthorized | 500 Error
```

## Security Configuration

### Authentication Flow
1. Client sends JWT token in `Authorization: Bearer {token}` header
2. `FirebaseTokenFilter` validates token with Firebase
3. User ID extracted from token claims
4. Request proceeds with authenticated user context

### Authorization Rules
- **Public Endpoints**: All GET requests for announcements (no auth required)
- **Create/Update/Delete**: Requires authentication
- **Ownership Check**: Only creator can update/delete their announcements
- **Admin Management**: Admin users can access all announcements

### Endpoints Requiring Authentication (SecurityConfig)
```java
.requestMatchers("POST", "/api/institutions/*/announcements").authenticated()
.requestMatchers("PUT", "/api/institutions/*/announcements/**").authenticated()
.requestMatchers("DELETE", "/api/institutions/*/announcements/**").authenticated()
.requestMatchers("POST", "/api/institutions/*/announcements/*/view").authenticated()
.requestMatchers("POST", "/api/institutions/*/announcements/*/toggle-pin").authenticated()
.requestMatchers("GET", "/api/institutions/*/announcements/manage/**").authenticated()
.requestMatchers("GET", "/api/institutions/*/announcements/audience").authenticated()
```

## Usage Examples

### Example 1: Create an announcement (using REST client or frontend)
```bash
curl -X POST http://localhost:8080/api/institutions/RVU/announcements \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Important: Semester Results Released",
    "description": "Results are now available on the student portal",
    "content": "Dear Students,\n\nYour semester results have been declared...",
    "priority": "HIGH",
    "category": "ACADEMIC",
    "status": "PUBLISHED",
    "targetAudience": ["STUDENTS"],
    "targetDepartments": [],
    "scheduledFor": 0,
    "attachmentUrls": ["https://example.com/results.pdf"]
  }'
```

### Example 2: Get all announcements
```bash
curl http://localhost:8080/api/institutions/RVU/announcements
```

### Example 3: Search announcements
```bash
curl "http://localhost:8080/api/institutions/RVU/announcements/search?q=results"
```

### Example 4: Mark announcement as viewed
```bash
curl -X POST http://localhost:8080/api/institutions/RVU/announcements/{id}/view \
  -H "Authorization: Bearer eyJhbGc..."
```

## Error Handling

### Common HTTP Status Codes
- **200 OK**: Successful GET or update operation
- **201 Created**: Successful POST (create) operation
- **400 Bad Request**: Invalid input (e.g., empty search query)
- **401 Unauthorized**: Missing or invalid authentication token
- **403 Forbidden**: User lacks permission (e.g., trying to update another user's announcement)
- **404 Not Found**: Announcement doesn't exist
- **500 Internal Server Error**: Server-side exception

### Error Response Format
```json
{
  "error": "Error message describing the problem"
}
```

## Firestore Rules (Recommended)

For production, set up Firestore security rules:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /Institutions/{institutionId}/announcements/{announcementId} {
      // Read: Anyone can read published announcements
      allow read: if resource.data.status == "PUBLISHED";
      
      // Create: Only authenticated users
      allow create: if request.auth != null;
      
      // Update/Delete: Only creator or admin
      allow update, delete: if request.auth.uid == resource.data.createdBy;
    }
  }
}
```

## Testing Checklist

- [ ] Create announcement with all required fields
- [ ] Create draft announcement
- [ ] Update published announcement
- [ ] Delete announcement (as creator)
- [ ] Attempt to update/delete another user's announcement (should fail)
- [ ] Get all announcements
- [ ] Filter by category
- [ ] Filter by priority
- [ ] Search with keywords
- [ ] Mark announcement as viewed
- [ ] Pin/unpin announcement
- [ ] Get management (my announcements)
- [ ] Get management (all announcements)
- [ ] Get announcements by audience
- [ ] Test without authentication (public endpoints work)
- [ ] Test without authentication (protected endpoints fail with 401)

## Database Backup Strategy

Firestore collections are automatically backed up by Google Cloud. For additional security:
1. Enable Firestore backups in Google Cloud Console
2. Set retention policy for backups
3. Test restore procedures periodically

## Performance Considerations

1. **Indexing**: Firestore automatically creates necessary indexes
2. **Pagination**: Current implementation returns all results. For large datasets, implement pagination:
   - Use `Query.limit()` and `Query.offset()`
   - Add pagination parameters to API endpoints

3. **Caching**: Consider adding caching for:
   - Popular announcements
   - Category/priority filtered results
   - Search results

## Future Enhancements

1. **Email Notifications**: Send emails to targeted users when announcement is published
2. **Push Notifications**: Send push notifications via Firebase Cloud Messaging
3. **Scheduled Publishing**: Implement background jobs to publish scheduled announcements
4. **Rich Text Editor**: Support HTML/markdown content in place of plain text
5. **Comments/Replies**: Allow users to comment on announcements
6. **Analytics**: Track anonymous views, engagement metrics
7. **Bulk Operations**: Create/update multiple announcements
8. **Approval Workflow**: Require admin approval before publishing
9. **Template System**: Create reusable announcement templates
10. **Integration**: Integrate with other systems (email, SMS, social media)

## Troubleshooting

### Issue: 401 Unauthorized on protected endpoints
**Solution**: Ensure valid Firebase token is in `Authorization: Bearer {token}` header

### Issue: 403 Forbidden when updating announcement
**Solution**: Only the creator (matched by `createdBy` field) can update. Use a different user or ask creator to make changes

### Issue: Firestore quota exceeded
**Solution**: 
- Check Firestore usage dashboard
- Implement pagination to reduce document reads
- Clear archived announcements regularly

### Issue: Search returns no results
**Solution**: Search is case-insensitive but requires all words to match. Try shorter, more general search terms.

## Support

For issues or questions about the announcements backend:
1. Check the test results in your IDE
2. Review Firestore console for data verification
3. Check Spring Boot logs for detailed error messages
4. Verify Firebase configuration is correct

---

**Last Updated**: 2026-02-17
**Version**: 1.0
