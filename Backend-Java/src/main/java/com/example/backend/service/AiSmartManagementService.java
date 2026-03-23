package com.example.backend.service;

import com.example.backend.dto.SubjectWiseAttendance;
import com.example.backend.models.TimetableEntry;
import com.example.backend.models.User;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;


import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutionException;

@Service
public class AiSmartManagementService {

    private final ChatClient chatClient;
    private final AttendanceService attendanceService;
    private final TimetableService timetableService;
    private final UserService userService;

    public AiSmartManagementService(ChatClient.Builder builder,
                                    AttendanceService attendanceService,
                                    TimetableService timetableService,
                                    UserService userService) {
        this.chatClient = builder
                .defaultSystem("You are an Institutional Decision Support AI. Your goal is to help HODs and Professors make informed decisions about leaves and scheduling.")
                .build();
        this.attendanceService = attendanceService;
        this.timetableService = timetableService;
        this.userService = userService;
    }

    public String getLeaveApprovalInsight(String institutionId, String studentUid, String startDate, String endDate) throws ExecutionException, InterruptedException {
        List<SubjectWiseAttendance> currentAttendance = attendanceService.getSubjectWiseAttendance(institutionId, studentUid);
        
        StringBuilder data = new StringBuilder();
        data.append("Current Attendance:\n");
        for (SubjectWiseAttendance sa : currentAttendance) {
            data.append("- ").append(sa.getCourseName()).append(": ").append(sa.getAttendancePercentage()).append("%\n");
        }
        data.append("\nLeave Requested: ").append(startDate).append(" to ").append(endDate);

        return chatClient.prompt()
                .user(u -> u.text("Analyze the impact of this leave on the student's attendance. Predict if it will drop below the 75% mandatory threshold. Provide a 'Recommendation' (Approve/Reject) with a 1-sentence reason.\n\nData:\n{data}")
                        .param("data", data.toString()))
                .call()
                .content();
    }

    public String getSubstitutionSuggestions(String institutionId, String facultyUid, String date, String timeSlotId) throws ExecutionException, InterruptedException {
        // 1. Get the day of the week from the date
        LocalDate localDate = LocalDate.parse(date);
        String dayOfWeek = localDate.getDayOfWeek().getDisplayName(TextStyle.FULL, Locale.ENGLISH);

        // 2. Fetch all faculty for the institution
        List<User> allFaculty = userService.getUsers(institutionId, "faculty");

        // 3. Find who is FREE during that specific day and timeSlotId
        StringBuilder freeFacultyInfo = new StringBuilder();
        for (User faculty : allFaculty) {
            if (faculty.getUid().equals(facultyUid)) continue;

            List<TimetableEntry> schedule = timetableService.getTimetableForFaculty(institutionId, faculty.getUid());
            boolean isBusy = schedule.stream()
                    .anyMatch(e -> e.getDay().equalsIgnoreCase(dayOfWeek) && e.getTimeSlotId().equals(timeSlotId));

            if (!isBusy) {
                freeFacultyInfo.append("- ").append(faculty.getDisplayName())
                        .append(" (Dept: ").append(faculty.getDepartmentId()).append(")\n");
            }
        }

        return chatClient.prompt()
                .user(u -> u.text("Based on the following list of available (free) faculty for the slot '{slot}' on {day}, suggest the best 2 substitutes for the absent professor. Prioritize same department if possible.\n\nAvailable Faculty:\n{faculty}")
                        .param("slot", timeSlotId)
                        .param("day", dayOfWeek)
                        .param("faculty", freeFacultyInfo.toString()))
                .call()
                .content();
    }
}
