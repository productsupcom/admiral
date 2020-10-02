CREATE DATABASE IF NOT EXISTS ansible;

USE ansible;

CREATE TABLE `group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `variables` varchar(8192) NOT NULL DEFAULT '{}',
  `enabled` tinyint(1) NOT NULL DEFAULT '0',
  `monitored` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `childgroups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `child_id` int(11) NOT NULL,
  `parent_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `childid` (`child_id`,`parent_id`),
  KEY `childgroups_child_id` (`child_id`),
  KEY `childgroups_parent_id` (`parent_id`),
  CONSTRAINT `childgroups_ibfk_2` FOREIGN KEY (`parent_id`) REFERENCES `group` (`id`),
  CONSTRAINT `childgroups_ibfk_3` FOREIGN KEY (`child_id`) REFERENCES `group` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `host` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `host` varchar(255) NOT NULL,
  `hostname` varchar(255) NOT NULL,
  `domain` varchar(250) DEFAULT NULL,
  `variables` varchar(8192) NOT NULL DEFAULT '{}',
  `enabled` tinyint(1) NOT NULL,
  `monitored` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `host_host` (`host`),
  UNIQUE KEY `host_hostname` (`hostname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `hostgroups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `host_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `host_id` (`host_id`,`group_id`),
  KEY `hostgroups_host_id` (`host_id`),
  KEY `hostgroups_group_id` (`group_id`),
  CONSTRAINT `hostgroups_ibfk_1` FOREIGN KEY (`host_id`) REFERENCES `host` (`id`) ON DELETE CASCADE,
  CONSTRAINT `hostgroups_ibfk_2` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `hostgroup_view` AS
SELECT
    `hostgroups`.`id` AS `relationship_id`,
    `host`.`hostname` AS `host`,
    `hostgroups`.`host_id` AS `host_id`,
    `group`.`name` AS `group`,
    `hostgroups`.`group_id` AS `group_id`
FROM `hostgroups`
LEFT JOIN `group`
    ON `hostgroups`.`group_id` = `group`.`id`
LEFT JOIN `host`
    ON `hostgroups`.`host_id` = `host`.`id`
WHERE `host`.`enabled` = 1
ORDER BY `group`.`name`;

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `childgroups_view` AS
SELECT
    `childgroups`.`id` AS `relationship_id`,
    `gparent`.`name` AS `parent`,
    `gparent`.`id` AS `parent_id`,
    `gchild`.`name` AS `child`,
    `gchild`.`id` AS `child_id`
FROM `childgroups`
LEFT JOIN `group` `gparent`
	ON `childgroups`.`parent_id` = `gparent`.`id`
LEFT JOIN `group` `gchild`
	ON `childgroups`.`child_id` = `gchild`.`id`
WHERE `gparent`.`enabled` = 1
    AND `gchild`.`enabled` = 1
ORDER BY `gparent`.`name`;

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `inventory` AS
WITH RECURSIVE inherited (child_id, parent_id) AS (
SELECT
	child_id,
	parent_id
from
	childgroups_view cv
UNION ALL
SELECT
	cv.child_id,
	i.parent_id
FROM
	inherited i
JOIN childgroups_view cv ON
	i.child_id = cv.parent_id )
SELECT
	ifnull(concat(host.hostname, '.', host.domain),
	host.host) AS host,
	host.variables AS host_vars,
	GROUP_CONCAT(DISTINCT g1.name) AS direct_group,
	GROUP_CONCAT(DISTINCT g2.name) AS inherited_groups
FROM
	host
LEFT JOIN hostgroup_view hv ON
	host.id = hv.host_id
LEFT JOIN inherited i ON
	hv.group_id = i.child_id
LEFT JOIN `group` g1 ON
	hv.group_id = g1.id
LEFT JOIN `group` g2 ON
	i.parent_id = g2.id
WHERE
	host.enabled = 1
GROUP BY
	host.hostname
ORDER BY
	host.hostname;
