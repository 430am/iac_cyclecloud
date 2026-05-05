resource "azurerm_shared_image_gallery" "cyclecloud" {
    location = var.location
    name = "sig-${random_pet.naming.id}"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    description = "Shared Image Gallery for CycleCloud"
    tags = local.common_tags
    
}

resource "azurerm_shared_image" "cyclecloud" {
    gallery_name = azurerm_shared_image_gallery.cyclecloud.name
    location = var.location
    name = "image-${random_pet.naming.id}"
    os_type = "Linux"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    
    identifier {
        offer = "ubuntu-hpc"
        publisher = "microsoft-dsvm"
        sku = "2404"
    }
    
    description = "Shared Image for CycleCloud installed on Ubuntu 24.04"
    hyper_v_generation = "V2"
    min_recommended_vcpu_count = 4
    min_recommended_memory_in_gb = 16
    accelerated_network_support_enabled = true
    disk_controller_type_nvme_enabled = true
}