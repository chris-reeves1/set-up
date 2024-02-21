import jenkins.model.*
import hudson.security.*

// Disable setup wizard
Jenkins.instance.installState = InstallState.INITIAL_SETUP_COMPLETED

// Set up security (example: disable security)
Jenkins.instance.setSecurityRealm(new HudsonPrivateSecurityRealm(false))
Jenkins.instance.setAuthorizationStrategy(new FullControlOnceLoggedInAuthorizationStrategy())
Jenkins.instance.save()
