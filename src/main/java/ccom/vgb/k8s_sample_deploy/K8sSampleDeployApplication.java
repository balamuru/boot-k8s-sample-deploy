package ccom.vgb.k8s_sample_deploy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class K8sSampleDeployApplication {

	public static void main(String[] args) {
		SpringApplication.run(K8sSampleDeployApplication.class, args);
	}


	@GetMapping("/hello")
	public String hello() {
		return "Hello, Kubernetes!!!!!##";
	}
}
