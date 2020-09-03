##
# Required parameters
##

variable "location" {
  description = "Azure region"
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

variable "db_id" {
  description = "identifier appended to db name (productname-environment-mysql<db_id>)"
  type        = string
  default     = "1337"
}

variable "sku_name" {
  type        = string
  description = "Azure database for MySQL sku name"
  default     = "GP_Gen5_2"
}

variable "storage_mb" {
  type        = number
  description = "Azure database for MySQL Sku Size"
  default     = "10240"
}

variable "mysql_version" {
  type        = string
  description = "MySQL version"
  default     = "8.0"
}

variable "threat_detection_policy" {
  description = "nested mode: NestingList, min items: 1, max items: 1"
  type = set(object(
    {
      enabled                     = string
      storage_endpoint            = string
      storage_account_access_key  = string
      retention_days              = number
    }
  ))
}

##
# Optional Parameters
##

variable "administrator_login" {
  type        = string
  description = "Database administrator login name"
  default     = "az_dbadmin"
}

variable "backup_retention_days" {
  type        = number
  description = "Backup retention days for the server, supported values are between 7 and 35 days."
  default     = "7"
}

variable "geo_redundant_backup_enabled" {
  type        = string
  description = "Turn Geo-redundant server backups on/off. This allows you to choose between locally redundant or geo-redundant backup storage in the General Purpose and Memory Optimized tiers. When the backups are stored in geo-redundant backup storage, they are not only stored within the region in which your server is hosted, but are also replicated to a paired data center. This provides better protection and ability to restore your server in a different region in the event of a disaster. This is not supported for the Basic tier."
  default     = "false"
}

variable "infrastructure_encryption_enabled" {
  type        = string
  description = "Whether or not infrastructure is encrypted for this server. Defaults to false. Changing this forces a new resource to be created."
  default     = "false"
}

variable "ssl_enforcement_enabled" {
  type        = string
  description = "Specifies if SSL should be enforced on connections. Possible values are true and false."
  default     = "true"
}

##
# Required MySQL Server Parameters
##

variable "audit_log_enabled" {
  type        = string
  description = "The value of this variable is ON or OFF to Allow to audit the log."
  default     = "ON"
}

variable "character_set_server" {
  type        = string
  description = "Use charset_name as the default server character set."
  default     = "UTF8MB4"
}

variable "event_scheduler" {
  type        = string
  description = "Indicates the status of the Event Scheduler. It is always OFF for a replica server to keep the replication consistency."
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

variable "create_mode" {
    type        = string
    description = "Can be used to restore or replicate existing servers. Possible values are Default, Replica, GeoRestore, and PointInTimeRestore. Defaults to Default"
}

variable "mysql_config" {
  type        = map(string)
  description = "A map of mysql additional configuration parameters to values."
  default     = {}
}

locals {
  mysql_config = merge({
    audit_log_enabled                       = var.audit_log_enabled
    event_scheduler                         = var.create_mode != "Replica" ? var.event_scheduler : "ON"
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
}