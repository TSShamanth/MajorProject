# Use an official OpenJDK runtime as a parent image
FROM eclipse-temurin:21-jre-jammy

# Set the working directory in the container
WORKDIR /app

# Copy the executable JAR file from the host to the container
# The JAR file is created by the Maven build process
COPY target/backend-0.0.1-SNAPSHOT.jar .

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Run the JAR file 
# java -jar backend-0.0.1-SNAPSHOT.jar
ENTRYPOINT ["java", "-jar", "backend-0.0.1-SNAPSHOT.jar"]
