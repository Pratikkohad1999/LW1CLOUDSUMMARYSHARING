apiVersion: v1
clusters:
- cluster:
   server: https://api.ocp-ap3.prod.nextcle.com:6443
  name: api-ocp-ap3-prod-nextcle-com:6443
- cluster:
   certificate-authority: C:\users\Asus\.minikube\ca.crt
   server: https://192.168.99.101:8443
  name: minikube
contexts:
- context:
   cluster: minikube
   user: minikube
  name: minikube
- context:
   cluster: api-ocp-ap3-prod-nextcle-com:6443
   namespace: my11
   user: pratik1999/api-ocp-ap3-prod-nextcle-com:6443
  name: my11/api-ocp-ap3-prod-nextcle-com:6443/pratik1999 
current-context: my11/api-ocp-ap3-prod-nextcle-com:6443/pratik1999
kind: Config
preferences: {}
users:
- name: minikube
  user:
   client-certificate: C:\Users\Asus\.minikube\profiles\minikube\client.crt 
   client-key: C:\users\Asus\.minikube\client.key
- name: pratik1999/api-ocp-ap3-prod-nextcle-com:6443
  user:
   token: mphSndeCl2VIQA5Na4mje_ECmjexuADrIny0OdoQhf4


 provider "kubernetes" { 
config_context_cluster      = "minikube" 
}
 resource "kubernetes_pod" "pods" {
   metadata { 
       name = "terraform-kubernetes" 
   } 
  spec { 
     container{
       image = "vimal13/apache-webserver-php"
       name = "my_os1"
       args = ["-listen=:80" ]
       env {
         name = "environment" 
         value = "test" 
      }
    }
  }
}
