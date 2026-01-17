#!/bin/bash
# Java/JVM profile aliases
# Maven, Gradle, Spring Boot, SDKMAN

###############################################################################
# Maven
###############################################################################

alias mvn='mvn'
alias mci='mvn clean install'
alias mcis='mvn clean install -DskipTests'
alias mcp='mvn clean package'
alias mcps='mvn clean package -DskipTests'
alias mt='mvn test'
alias mts='mvn test -DskipTests'
alias mc='mvn compile'
alias mdep='mvn dependency:tree'
alias mver='mvn versions:display-dependency-updates'

###############################################################################
# Gradle
###############################################################################

alias gw='./gradlew'
alias gwb='./gradlew build'
alias gwbs='./gradlew build -x test'
alias gwc='./gradlew clean'
alias gwcb='./gradlew clean build'
alias gwt='./gradlew test'
alias gwr='./gradlew run'
alias gwdep='./gradlew dependencies'

###############################################################################
# Spring Boot
###############################################################################

alias sbr='mvn spring-boot:run'
alias sbrd='mvn spring-boot:run -Dspring-boot.run.profiles=dev'
alias sbrp='mvn spring-boot:run -Dspring-boot.run.profiles=prod'
alias gwsbr='./gradlew bootRun'

###############################################################################
# SDKMAN (if installed)
###############################################################################

# Source SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

###############################################################################
# Java Version Management
###############################################################################

# List installed Java versions
jversions() {
  if command -v sdk &>/dev/null; then
    sdk list java
  elif [[ -d "/usr/lib/jvm" ]]; then
    ls /usr/lib/jvm
  elif [[ "$DOTFILES_OS" == "darwin" ]]; then
    /usr/libexec/java_home -V 2>&1
  fi
}

# Set JAVA_HOME helper
jset() {
  if command -v sdk &>/dev/null; then
    sdk use java "$1"
  else
    echo "SDKMAN not installed. Run: curl -s \"https://get.sdkman.io\" | bash"
  fi
}

###############################################################################
# Helper Functions
###############################################################################

# Quick mvn wrapper
m() {
  if [[ -f "./mvnw" ]]; then
    ./mvnw "$@"
  else
    mvn "$@"
  fi
}

# Quick gradle wrapper
g() {
  if [[ -f "./gradlew" ]]; then
    ./gradlew "$@"
  else
    gradle "$@"
  fi
}

# Run main class
jrun() {
  [[ -z "$1" ]] && { echo "Usage: jrun <MainClass>"; return 1; }
  mvn exec:java -Dexec.mainClass="$1"
}
