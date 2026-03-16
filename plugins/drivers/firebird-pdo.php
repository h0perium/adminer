<?php
namespace Adminer;

/**
 * Firebird driver (PDO-based) for Adminer.
 *
 * Goal: register Firebird in the login "System" dropdown and provide basic connectivity using PDO_FIREBIRD.
 */

add_driver('firebird', 'Firebird (PDO)');

if (isset($_GET['firebird'])) {
	define('DRIVER', 'firebird');

	if (extension_loaded('pdo_firebird')) {
		class Min_DB {
			var $extension = 'Firebird (PDO)', $server_info, $affected_rows, $errno, $error, $_link;
			private $server, $username, $password;

			function connect($server, $username, $password) {
				$this->server = $server;
				$this->username = $username;
				$this->password = $password;
				return true; // actual connection happens in select_db
			}

			function select_db($database) {
				try {
					$host = $this->server ?: 'localhost';
					$dsn = "firebird:dbname={$host}:{$database};charset=UTF8";
					$this->_link = new \PDO($dsn, $this->username, $this->password, [
						\PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
						\PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
					]);
					$this->server_info = 'Firebird';
					return true;
				} catch (\Throwable $e) {
					$this->errno = 1;
					$this->error = $e->getMessage();
					return false;
				}
			}

			function quote($string) {
				return $this->_link ? $this->_link->quote($string) : "'" . str_replace("'", "''", $string) . "'";
			}

			function query($query, $unbuffered = false) {
				try {
					if (!$this->_link) {
						$this->errno = 1;
						$this->error = 'No database selected.';
						return false;
					}
					$trim = ltrim($query);
					$isSelect = (stripos($trim, 'SELECT') === 0) || (stripos($trim, 'WITH') === 0);
					if ($isSelect) {
						$stmt = $this->_link->query($query);
						return new Min_Result($stmt);
					}
					$this->affected_rows = $this->_link->exec($query);
					return true;
				} catch (\Throwable $e) {
					$this->errno = 1;
					$this->error = $e->getMessage();
					return false;
				}
			}

			function multi_query($query) { return $this->query($query); }
			function store_result() { return false; }
			function next_result() { return false; }
		}

		class Min_Result {
			var $num_rows = 0;
			private $stmt;
			private $col = 0;

			function __construct($stmt) { $this->stmt = $stmt; }

			function fetch_assoc() {
				$row = $this->stmt->fetch(\PDO::FETCH_ASSOC);
				return $row ?: null;
			}

			function fetch_row() {
				$row = $this->stmt->fetch(\PDO::FETCH_NUM);
				return $row ?: null;
			}

			function fetch_field() {
				$meta = $this->stmt->getColumnMeta($this->col++);
				$name = $meta['name'] ?? ('col' . $this->col);
				return (object) [
					'name' => $name,
					'orgname' => $name,
					'type' => 0,
					'charsetnr' => 0,
				];
			}
		}

		class Min_Driver extends Min_SQL { }

		function idf_escape($idf) { return '"' . str_replace('"', '""', $idf) . '"'; }
		function table($idf) { return idf_escape($idf); }
		function get_databases($flush) { return []; }
		function limit($query, $where, $limit, $offset = 0, $separator = " ") {
			$first = ($limit !== null ? " FIRST $limit" : "");
			$skip = ($offset ? " SKIP $offset" : "");
			return preg_replace('/^SELECT\s+/i', "SELECT$first$skip ", "$query$where", 1);
		}
		function limit1($table, $query, $where, $separator = "\n") { return limit($query, $where, 1, 0, $separator); }
	}
}
