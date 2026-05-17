package com.example.backend.service;

import com.example.backend.models.*;
import com.example.backend.dto.SubjectWiseAttendance;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class AiInsightService {

    private static final Logger logger = LoggerFactory.getLogger(AiInsightService.class);
    private final ChatClient chatClient;
    private final UserService userService;
    private final MarksService marksService;
    private final AttendanceService attendanceService;
    private final LeaveService leaveService;
    private final PlacementService placementService;

    public AiInsightService(ChatClient.Builder builder, 
                            UserService userService, 
                            MarksService marksService, 
                            AttendanceService attendanceService, 
                            LeaveService leaveService, 
                            PlacementService placementService) {
        this.chatClient = builder
                .defaultSystem("You are an expert Educational AI Analyst. Your goal is to provide actionable, data-driven insights for students and faculty.\n\n" +
                        "CORE AREAS:\n" +
                        "1. Student Success Predictor (Academics & Placement Likelihood)\n" +
                        "2. At-Risk Identification\n" +
                        "3. Attendance Anomaly Detection\n" +
                        "4. Leave Impact Forecaster\n\n" +
                        "OUTPUT FORMAT:\n" +
                        "- Use professional, encouraging, and clear Markdown.\n" +
                        "- Use sections with clear headings.\n" +
                        "- Use bullet points for specific observations.\n" +
                        "- Keep it concise but comprehensive.")
                .build();
        this.userService = userService;
        this.marksService = marksService;
        this.attendanceService = attendanceService;
        this.leaveService = leaveService;
        this.placementService = placementService;
    }

    public String generateInsights(String institutionId, String studentId) throws ExecutionException, InterruptedException {
        logger.info("Generating AI insights for student: {} in institution: {}", studentId, institutionId);

        // 1. Gather all data
        User student = userService.getUserById(institutionId, studentId);
        if (student == null) return "Student data not found.";

        Map<String, Object> academicSummary = marksService.getAcademicSummary(institutionId, studentId);
        List<Marks> recentMarks = marksService.getMarksByStudent(institutionId, studentId);
        List<SubjectWiseAttendance> subjectAttendance = attendanceService.getSubjectWiseAttendance(institutionId, studentId);
        List<LeaveApplication> leaveHistory = leaveService.getLeaveHistory(institutionId, studentId);
        List<PlacementApplication> placementApps = placementService.getStudentApplications(institutionId, studentId);
        PlacementRegistration placementReg = placementService.getRegistration(institutionId, studentId);

        // 2. Prepare Data Context for LLM
        StringBuilder context = new StringBuilder();
        context.append("Student Profile:\n")
                .append("- Name: ").append(student.getDisplayName()).append("\n")
                .append("- Program: ").append(student.getProgramme()).append(", Sem: ").append(student.getSem()).append("\n")
                .append("- Current GPA: ").append(student.getCurrentGPA()).append("\n")
                .append("- GPA History: ").append(student.getGpaHistory()).append("\n\n");

        context.append("Academic Summary:\n").append(academicSummary).append("\n\n");
        
        context.append("Subject-wise Attendance:\n");
        for (SubjectWiseAttendance sa : subjectAttendance) {
            context.append("- ").append(sa.getCourseName()).append(": ")
                    .append(sa.getAttendancePercentage()).append("% (")
                    .append(sa.getAttendedClasses()).append("/").append(sa.getTotalClasses()).append(")\n");
        }
        context.append("\n");

        context.append("Recent Marks/Assessments:\n");
        recentMarks.stream().limit(10).forEach(m -> {
            context.append("- ").append(m.getCourseCode()).append(" (").append(m.getType()).append("): ")
                    .append(m.getObtainedMarks()).append("/").append(m.getTotalMarks()).append("\n");
        });
        context.append("\n");

        context.append("Leave History:\n");
        leaveHistory.stream().limit(5).forEach(l -> {
            context.append("- ").append(l.getStartDate()).append(" to ").append(l.getEndDate())
                    .append(" (").append(l.getStatus()).append("): ").append(l.getReason()).append("\n");
        });
        context.append("\n");

        context.append("Placement Context:\n");
        if (placementReg != null) {
            context.append("- Registered: Yes\n")
                    .append("- CGPA: ").append(placementReg.getCgpa()).append("\n")
                    .append("- Skills: ").append(placementReg.getSkills()).append("\n")
                    .append("- Backlogs: ").append(placementReg.getBacklogCount()).append("\n");
        } else {
            context.append("- Registered: No\n");
        }
        context.append("- Applications: ").append(placementApps.size()).append("\n");
        placementApps.forEach(a -> {
            context.append("  * ").append(a.getCompanyName()).append(" (").append(a.getJobRole()).append("): ").append(a.getStatus()).append("\n");
        });

        // 3. Call Gemini
        return chatClient.prompt()
                .user(u -> u.text("Please analyze the following student data and provide insights for the 4 core areas defined in your system instructions.\n\n" +
                                 "Data Context:\n{data}")
                        .param("data", context.toString()))
                .call()
                .content();
    }
}
