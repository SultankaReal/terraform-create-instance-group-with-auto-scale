#Create instance group
#Link to terraform documentation - https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance_group

resource "yandex_compute_instance_group" "group1" {
  name                = "test-ig"
  folder_id           = var.default_folder_id
  service_account_id  = var.default_service_account_id
  deletion_protection = false //Flag that protects the instance group from accidental deletion
  instance_template {
    platform_id = "standard-v3" //The ID of the hardware platform configuration for the instance. The default is 'standard-v1'
    resources {
      memory = 2
      cores  = 2
    }
    boot_disk {
      mode = "READ_WRITE" //The access mode to the disk resource. By default a disk is attached in READ_WRITE mode
      initialize_params { //Parameters used for creating a disk alongside the instance
        image_id = var.default_image_id //The disk image to initialize this disk from
        size     = 10 //disk_size
      }
    }
    network_interface {
      network_id = var.default_network_id
      subnet_ids = [var.default_subnet_id_zone_a, var.default_subnet_id_zone_b, var.default_subnet_id_zone_c]
    }
    labels = { //A set of key/value label pairs to assign to the instance group
      label1 = "label1-value"
      label2 = "label2-value"
    }
    metadata = { //A set of metadata key/value pairs to make available from within the instance
      ssh-keys = "nursultan:${file("~/.ssh/id_rsa.pub")}"
    }
    network_settings {
      type = "STANDARD" //Network acceleration type. By default a network is in STANDARD mode (STANDARD or SOFTWARE_ACCELERATED)
    }
  }

  variables = { //A set of key/value variables pairs to assign to the instance group
    test_key1 = "test_value1"
    test_key2 = "test_value2"
  }

  scale_policy {
    auto_scale {
      initial_size = 3 //The initial number of instances in the instance group
      measurement_duration = 90 //The amount of time, in seconds, that metrics are averaged for. If the average value at the end of the interval is higher than the cpu_utilization_target, the instance group will increase the number of virtual machines in the group.
      min_zone_size = 1 //The minimum number of virtual machines in a single availability zone
      max_size = 9 //The maximum number of virtual machines in the group
      warmup_duration = 120 //The warm-up time of the virtual machine, in seconds. During this time, traffic is fed to the virtual machine, but load metrics are not taken into account
      stabilization_duration = 300
      custom_rule {
        rule_type = "UTILIZATION"
        /* 
         Rule type: UTILIZATION - This type means that the metric applies to one instance. First, Instance Groups calculates the average metric value for each instance, then averages the values for instances in one availability zone. This type of metric must have the instance_id label. WORKLOAD - This type means that the metric applies to instances in one availability zone. This type of metric must have the zone_id label.
        */
        metric_type = "GAUGE" //Metric type, GAUGE or COUNTER
        metric_name = "CPU" //The name of metric
        target = 5 //Target metric value level
        folder_id = var.default_folder_id
        service = "compute" //Service of custom metric in Yandex Monitoring that should be used for scaling
      }
    }
  }

  allocation_policy { //The allocation policy of the instance group by zone and region
    zones = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
  }

  deploy_policy { //The deployment policy of the instance group
    max_unavailable = 3 //The maximum number of running instances that can be taken offline (stopped or deleted) at the same time during the update process
    max_creating    = 3 //The maximum number of instances that can be created at the same time
    max_expansion   = 3 //The maximum number of instances that can be temporarily allocated above the group's target size during the update process
    max_deleting    = 1 //The maximum number of instances that can be deleted at the same time
    strategy = "proactive" //Affects the lifecycle of the instance during deployment. If set to proactive (default), Instance Groups can forcefully stop a running instance. If opportunistic, Instance Groups does not stop a running instance. Instead, it will wait until the instance stops itself or becomes unhealthy
  }
}