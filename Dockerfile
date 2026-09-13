# Stage 1: compile the source and assemble the WAR, using the same Tomcat
# image's own bundled servlet-api/jsp-api jars (no extra download needed).
FROM tomcat:9-jdk17 AS build
WORKDIR /src
COPY Medical_care/ ./Medical_care/
WORKDIR /src/Medical_care
RUN CP=$(find lib -name "*.jar" | tr '\n' ':')$(find /usr/local/tomcat/lib -name '*.jar' | tr '\n' ':') && \
    mkdir -p build && \
    javac -d build -cp "$CP" $(find src/java -name '*.java') && \
    mkdir -p war/WEB-INF/classes war/WEB-INF/lib && \
    cp -r web/. war/ && \
    cp -r build/* war/WEB-INF/classes/ && \
    cp lib/*.jar war/WEB-INF/lib/ && \
    cd war && jar -cf /app.war .

# Stage 2: run it - no compiler, no source, just the WAR in a clean Tomcat.
FROM tomcat:9-jdk17
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /app.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
