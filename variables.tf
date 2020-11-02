#
# Required parameters
##

variable "location" {
  description = "Specifies the supported Azure location to MySQL server resource"
  type        = string
}

variable "resource_group_name" {
  description = "name of the resource group to create the resource"
  type        = string
}

variable "names" {
  description = "names to be applied to resources"
  type        = map(string)
}

variable "tags" {
  description = "tags to be applied to resources"
  type        = map(string)
}

variable "server_id" {
  description = "identifier appended to server name for more info see https://github.com/openrba/python-azure-naming#azuredbformysql"
  type        = string
}

variable "sku_name" {
  description = "Azure database for MySQL sku name"
  type        = string
  default     = "GP_Gen5_2"
}

variable "storage_mb" {
  description = "Max storage allowed for a server"
  type        = number
  default     = "10240"
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0"
}

variable "administrator_login" {
  type        = string
  description = "Database administrator login name"
  default     = "az_dbadmin"
}

variable "administrator_password" {
  type        = string
  description = "Database administrator login name (leave blank to generate random string)"
  default     = ""
}

variable "create_mode" {
  description = "Can be used to restore or replicate existing servers. Possible values are Default, Replica, GeoRestore, and PointInTimeRestore. Defaults to Default"
  type        = string
  default = "Default"
}

variable "creation_source_server_id" {
  description = "the source server ID to use. use this only when creating a read replica server"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Specifies the number of days to keep in the Threat Detection audit logs"
  type        = number
  default     = 7
}

variable "ssl_enforcement_enabled" {
  description = "Specifies if SSL should be enforced on connections. Possible values are true and false."
  type        = bool
  default     = true
}

variable "infrastructure_encryption_enabled" {
  description = "Whether or not infrastructure is encrypted for this server. Defaults to false. Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "auto_grow_enabled" {
    description = "Enable/Disable auto-growing of the storage."
    type        = bool
    default     = false
}

variable "service_endpoints" {
    description = "Creates a virtual network rule in the subnet_id (values are virtual network subnet ids)."
    type        = map(string)
    default     = {}
}

variable "access_list" {
    description = "Access list for MySQL instance. Map off names to cidr ip start/end addresses"
    type        = map(object({ start_ip_address = string,
                               end_ip_address   = string }))
    default     = {}
}

variable "enable_mysql_ad_admin" {
  description = "Set a user or group as the AD administrator for an MySQL server in Azure"
  type        = bool
  default     = false
}

variable "ad_admin_login_name" {
  description = "The login name of the azure ad admin."
  type        = string
  default     = ""
}

##
# Optional Parameters
##

variable "backup_retention_days" {
  description = "Backup retention days for the server, supported values are between 7 and 35 days."
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Turn Geo-redundant server backups on/off. This allows you to choose between locally redundant or geo-redundant backup storage in the General Purpose and Memory Optimized tiers. When the backups are stored in geo-redundant backup storage, they are not only stored within the region in which your server is hosted, but are also replicated to a paired data center. This provides better protection and ability to restore your server in a different region in the event of a disaster. This is not supported for the Basic tier."
  type        = bool
  default     = false
}

variable "enable_threat_detection_policy" {
  description = "Threat detection policy configuration, known in the API as Server Security Alerts Policy."
  type        = bool
  default     = false 
}

variable "storage_endpoint" {
    description = "This blob storage will hold all Threat Detection audit logs. Required if state is Enabled."
    type        = string
    default     = ""
}

variable "storage_account_access_key" {
    description = "Specifies the identifier key of the Threat Detection audit storage account. Required if state is Enabled."
    type        = string
    default     = ""
}

##
# Required MySQL Server Parameters
##

variable "audit_log_enabled" {
  description = "The value of this variable is ON or OFF to Allow to audit the log."
  type        = string
  default     = "ON"
}

variable "character_set_server" {
  description = "Use charset_name as the default server character set."
  type        = string
  default     = "UTF8MB4"
}

variable "event_scheduler" {
  description = "Indicates the status of the Event Scheduler. It is always ON for a replica server."
  type        = string
  default     = "OFF"
}

variable "innodb_autoinc_lock_mode" {
  type        = string
  description = "The lock mode to use for generating auto-increment values."
  default     = "2"
}

variable "innodb_file_per_table" {
  type        = string
  description = "InnoDB stores the data and indexes for each newly created table in a separate .ibd file instead of the system tablespace. It cannot be updated any more for a master/replica server to keep the replication consistency."
  default     = "ON"
}

variable "join_buffer_size" {
  type        = string
  description = "The minimum size of the buffer that is used for plain index scans, range index scans, and joins that do not use indexes and thus perform full table scans."
  default     = "8000000"
}

variable "local_infile" {
  type        = string
  description = "This variable controls server-side LOCAL capability for LOAD DATA statements."
  default     = "ON"
}

variable "max_allowed_packet" {
  type        = string
  description = "The maximum size of one packet or any generated/intermediate string, or any parameter sent by the mysql_stmt_send_long_data() C API function."
  default     = "1073741824"
}

variable "max_connections" {
  type        = string
  description = "The maximum permitted number of simultaneous client connections. value 10-600"
  default     = "600"
}

variable "max_heap_table_size" {
  type        = string
  description = "This variable sets the maximum size to which user-created MEMORY tables are permitted to grow."
  default     = "64000000"
}

variable "performance_schema" {
  type        = string
  description = "The value of this variable is ON or OFF to indicate whether the Performance Schema is enabled."
  default     = "ON"
}

variable "replicate_wild_ignore_table" {
  type        = string
  description = "Creates a replication filter which keeps the slave thread from replicating a statement in which any table matches the given wildcard pattern. To specify more than one table to ignore, use comma-separated list."
  default     = "mysql.%,tempdb.%"
}

variable "slow_query_log" {
  type        = string
  description = "Enable or disable the slow query log"
  default     = "OFF"
}

variable "sort_buffer_size" {
  type        = string
  description = "Each session that must perform a sort allocates a buffer of this size."
  default     = "2000000"
}

variable "tmp_table_size" {
  type        = string
  description = "The maximum size of internal in-memory temporary tables. This variable does not apply to user-created MEMORY tables."
  default     = "64000000"
}

variable "transaction_isolation" {
  type        = string
  description = "The default transaction isolation level."
  default     = "READ-COMMITTED"
}

variable "query_store_capture_interval" {
    type        = string
    description = "The query store capture interval in minutes. Allows to specify the interval in which the query metrics are aggregated."
    default     = "15"
}

variable "query_store_capture_mode" {
    type        = string
    description = "The query store capture mode, NONE means do not capture any statements. NOTE: If performance_schema is OFF, turning on query_store_capture_mode will turn on performance_schema and a subset of performance schema instruments required for this feature."
    default     = "ALL"
}

variable "query_store_capture_utility_queries" {
    type        = string
    description = "Turning ON or OFF to capture all the utility queries that is executing in the system."
    default     = "YES"
}

variable "query_store_retention_period_in_days" {
    type        = string
    description = "The query store capture interval in minutes. Allows to specify the interval in which the query metrics are aggregated."
    default     = "7"
}

variable "query_store_wait_sampling_capture_mode" {
    type        = string
    description = "The query store wait event sampling capture mode, NONE means do not capture any wait events."
    default     = "ALL"
}

variable "query_store_wait_sampling_frequency" {
    type        = string
    description = "The query store wait event sampling frequency in seconds."
    default     = "30"
}

variable "mysql_config" {
  description = "A map of mysql additional configuration parameters to values."
  type        = map(string)
  default     = {}
}

variable "databases" {
  description = "Map of databases to create (keys are database names). Allowed values are the same as for database_defaults."
  type        = map
  default     = {}
}

variable "database_defaults" {
  description = "database default charset and collation (only applied to databases managed within this module)"
  type        = object({
                  charset   = string
                  collation = string
                })
  default     = {
                  charset   = "utf8"
                  collation = "utf8_unicode_ci"
                }
}

locals {
  mysql_config = merge({
    audit_log_enabled                       = var.audit_log_enabled
    event_scheduler                         = var.create_mode == "Replica" ? "ON" : var.event_scheduler
    innodb_autoinc_lock_mode                = var.innodb_autoinc_lock_mode
    local_infile                            = var.local_infile
    max_allowed_packet                      = var.max_allowed_packet
    max_connections                         = var.max_connections
    performance_schema                      = var.performance_schema
    skip_show_database                      = "OFF"
    slow_query_log                          = var.slow_query_log
    transaction_isolation                   = var.transaction_isolation
    query_store_capture_interval            = var.query_store_capture_interval
    query_store_capture_mode                = var.query_store_capture_mode
    query_store_capture_utility_queries     = var.query_store_capture_utility_queries
    query_store_retention_period_in_days    = var.query_store_retention_period_in_days
    query_store_wait_sampling_capture_mode  = var.query_store_wait_sampling_capture_mode
    query_store_wait_sampling_frequency     = var.query_store_wait_sampling_frequency
  }, (var.mysql_version != "5.6" || var.mysql_version != "5.7" ? {} : {
    replicate_wild_ignore_table             = var.replicate_wild_ignore_table
    innodb_file_per_table                   = var.innodb_file_per_table
    join_buffer_size                        = var.join_buffer_size
    max_heap_table_size                     = var.max_heap_table_size
    sort_buffer_size                        = var.sort_buffer_size
    tmp_table_size                          = var.tmp_table_size
  }))

  databases= zipmap(keys(var.databases), [ for database in values(var.databases): merge(var.database_defaults, database) ])
}
