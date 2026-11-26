// Script d'initialisation Jenkins (copie dans /var/jenkins_home/init.groovy.d/).
// Execute au demarrage de Jenkins :
//   1) cree l'agent "vm-vagrant" (label "vagrant") : la VM, qui a Docker, Minikube et kubectl
//   2) cree/met a jour le job "cc-devops" qui lit le Jenkinsfile du depot GitHub
import hudson.model.Node
import hudson.plugins.git.BranchSpec
import hudson.plugins.git.GitSCM
import hudson.slaves.DumbSlave
import hudson.slaves.JNLPLauncher
import hudson.slaves.RetentionStrategy
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import org.jenkinsci.plugins.workflow.job.WorkflowJob

def jenkins = Jenkins.get()

// ---------------------------------------------------------------- 1. agent
def AGENT = 'vm-vagrant'
if (jenkins.getNode(AGENT) == null) {
    def launcher = new JNLPLauncher()
    launcher.webSocket = true                       // l'agent se connecte via http://localhost:8080
    def agent = new DumbSlave(AGENT, '/home/vagrant/jenkins-agent', launcher)
    agent.labelString = 'vagrant'
    agent.numExecutors = 1
    agent.mode = Node.Mode.EXCLUSIVE                // uniquement pour les jobs qui demandent "vagrant"
    agent.retentionStrategy = new RetentionStrategy.Always()
    jenkins.addNode(agent)
    println "[cc-devops] agent ${AGENT} cree"
}
// secret de connexion de l'agent, lu par le script d'installation dans la VM
new File(jenkins.rootDir, "${AGENT}.secret").text = jenkins.getComputer(AGENT).jnlpMac

// ---------------------------------------------------------------- 2. job
def REPO = 'https://github.com/MarcDelon/CC-devops.git'
def scm = new GitSCM(GitSCM.createRepoList(REPO, null), [new BranchSpec('*/main')], null, null, [])
def definition = new CpsScmFlowDefinition(scm, 'Jenkinsfile')
definition.lightweight = true

def job = jenkins.getItem('cc-devops')
if (job != null && !(job instanceof WorkflowJob)) {
    job.delete()
    job = null
}
if (job == null) {
    job = jenkins.createProject(WorkflowJob, 'cc-devops')
}
job.description = 'CI/CD : GitHub -> tests -> image Docker -> Kubernetes (Minikube). Declenche par les git push (Poll SCM).'
job.definition = definition
job.save()
println "[cc-devops] job cc-devops relie a ${REPO} (Jenkinsfile)"

// premier build : il enregistre le declencheur pollSCM du Jenkinsfile
if (job.lastBuild == null || job.lastBuild.number < 2 || !job.lastBuild.result?.toString()?.equals('SUCCESS')) {
    job.scheduleBuild2(10)
}
