package com.example.backend.service;

import com.example.backend.models.*;
import org.apache.tika.Tika;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class AiPlacementService {

    private static final Logger logger = LoggerFactory.getLogger(AiPlacementService.class);
    private final ChatClient chatClient;
    private final PlacementService placementService;
    private final UserService userService;
    private final Tika tika = new Tika();

    public AiPlacementService(ChatClient.Builder builder, 
                               PlacementService placementService,
                               UserService userService) {
        this.chatClient = builder
                .defaultSystem("You are a Senior Career Counselor and Placement Analyst. Your goal is to help students prepare for their careers by analyzing their skills, academic performance, and placement opportunities.\n\n" +
                        "CORE TASKS:\n" +
                        "1. Placement Probability Engine: Calculate a readiness score (0-100%) and explain factors like CGPA, skills, and backlogs.\n" +
                        "2. Skill Gap Analyzer: Compare a student's skills with job requirements and suggest 3-5 specific topics to learn.\n" +
                        "3. Profile/Resume Scoring: Analyze how well a student's digital profile or uploaded resume matches a specific job role.\n" +
                        "4. Resume Parser: Extract key information from resume text and provide feedback on layout, content, and impact.")
                .build();
        this.placementService = placementService;
        this.userService = userService;
    }

    public String scoreResume(String institutionId, String studentId, String driveId, MultipartFile file) {
        try {
            logger.info("Attempting to parse resume for student: {} in drive: {}", studentId, driveId);
            String resumeText = tika.parseToString(file.getInputStream());
            
            if (resumeText == null || resumeText.trim().isEmpty()) {
                logger.warn("Extracted resume text is empty for student: {}", studentId);
                return "The uploaded file appears to be empty or unreadable. Please ensure it is a valid PDF or Word document.";
            }

            PlacementDrive drive = placementService.getDrive(institutionId, driveId);
            
            StringBuilder context = new StringBuilder();
            if (drive != null) {
                context.append("Job Description:\n")
                        .append("- Role: ").append(drive.getJobRole()).append("\n")
                        .append("- Company: ").append(drive.getCompanyName()).append("\n")
                        .append("- Requirements: ").append(drive.getEligibilityCriteria()).append("\n\n");
            } else {
                context.append("General Career Analysis (No specific drive selected).\n\n");
            }
            
            context.append("Resume Content:\n").append(resumeText);

            return chatClient.prompt()
                    .user(u -> u.text("Analyze the uploaded resume against the job description (if provided). Provide:\n" +
                                     "1. Resume Score (0-100)\n" +
                                     "2. Keyword Match (List matching and missing keywords)\n" +
                                     "3. Content Feedback (Strengths and areas for improvement)\n" +
                                     "4. Formatting Suggestions\n\nData:\n{data}")
                            .param("data", context.toString()))
                    .call()
                    .content();
        } catch (Exception e) {
            logger.error("Error in AI resume scoring: ", e);
            return "An error occurred while analyzing your resume: " + e.getMessage() + ". Please try again with a different file format (PDF preferred).";
        }
    }

    public String analyzeReadiness(String institutionId, String studentId) throws ExecutionException, InterruptedException {
        User student = userService.getUserById(institutionId, studentId);
        PlacementRegistration registration = placementService.getRegistration(institutionId, studentId);
        List<PlacementApplication> applications = placementService.getStudentApplications(institutionId, studentId);

        if (student == null) return "Student data not found.";

        StringBuilder context = new StringBuilder();
        context.append("Student Profile:\n")
                .append("- CGPA: ").append(student.getCurrentGPA()).append("\n")
                .append("- Program: ").append(student.getProgramme()).append("\n");

        if (registration != null) {
            context.append("- Skills: ").append(registration.getSkills()).append("\n")
                    .append("- Backlogs: ").append(registration.getBacklogCount()).append("\n");
        }
        context.append("- Total Applications: ").append(applications.size()).append("\n");

        return chatClient.prompt()
                .user(u -> u.text("Analyze the student's placement readiness and calculate a probability (0-100%) for securing a job in the current season. Suggest improvements.\n\nData:\n{data}")
                        .param("data", context.toString()))
                .call()
                .content();
    }

    public String analyzeSkillGap(String institutionId, String studentId, String driveId) throws ExecutionException, InterruptedException {
        PlacementRegistration registration = placementService.getRegistration(institutionId, studentId);
        PlacementDrive drive = placementService.getDrive(institutionId, driveId);

        if (registration == null || drive == null) return "Registration or Drive data not found.";

        StringBuilder context = new StringBuilder();
        context.append("Student Skills: ").append(registration.getSkills()).append("\n")
                .append("Job Role: ").append(drive.getJobRole()).append("\n")
                .append("Job Requirements: ").append(drive.getEligibilityCriteria());

        return chatClient.prompt()
                .user(u -> u.text("Compare the student's skills with the job requirements. List the 'Skill Gaps' and suggest exactly 3 learning resources or topics to bridge them.\n\nData:\n{data}")
                        .param("data", context.toString()))
                .call()
                .content();
    }

    public String scoreProfileMatch(String institutionId, String studentId, String driveId) throws ExecutionException, InterruptedException {
        PlacementRegistration registration = placementService.getRegistration(institutionId, studentId);
        PlacementDrive drive = placementService.getDrive(institutionId, driveId);

        if (registration == null || drive == null) return "Registration or Drive data not found.";

        StringBuilder context = new StringBuilder();
        context.append("Student Profile:\n")
                .append("- CGPA: ").append(registration.getCgpa()).append("\n")
                .append("- Skills: ").append(registration.getSkills()).append("\n")
                .append("- Backlogs: ").append(registration.getBacklogCount()).append("\n\n")
                .append("Job Description:\n")
                .append("- Role: ").append(drive.getJobRole()).append("\n")
                .append("- Requirements: ").append(drive.getEligibilityCriteria());

        return chatClient.prompt()
                .user(u -> u.text("Score the student's profile match for this specific drive (0-100%). Provide a 'Match Report' with pros, cons, and a 'Resume Score' based on the profile data.\n\nData:\n{data}")
                        .param("data", context.toString()))
                .call()
                .content();
    }
}
