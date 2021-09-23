<#
.SYNOPSIS
    SigmaDB class
.DESCRIPTION
    Class for database manipulation with the sigma database (sqlite3)
.EXAMPLE
    PS C:\> [SigmaDB]::New($database)
    Opens SQLite connection to $database (path to file).
    It'll create the database and tables if it doesn't exist
.EXAMPLE
    PS C:\> [SigmaDB]::Query($query)
    Queries $query to database without parameters
    Output expected
.EXAMPLE
    PS C:\> [SigmaDB]::Query($query, $parameters)
    Queries $query to database with parameters
    Output expected
.EXAMPLE
    PS C:\> [SigmaDB]::Update($query)
    Updates/Inserts/Creates $query to database without parameters
    No output expected
.EXAMPLE
    PS C:\> [SigmaDB]::Update($query, $parameters)
    Updates/Inserts/Creates $query to database with parameters
    No output expected
.INPUTS
    $database:   path to database
    $query:      sql query
    $parameters: parameters for query
.OUTPUTS
    Query result or None
.NOTES
    Author:     ncrqnt
    Date:       07.09.2021
    PowerShell: 7.1.4

    Changelog:
    1.2.0   22.09.2021  ncrqnt      Removed file_path
    1.1.1   16.09.2021  ncrqnt      Removed is_multidoc
    1.1.0   15.09.2021  ncrqnt      Added is_enabled field
    1.0.1   07.09.2021  ncrqnt      Fixed typo
                                    Added -ErrorAction Stop to Invoke functions
    1.0.0   07.09.2021  ncrqnt      Initial creation
#>

class SigmaDB {
    [string]$database

    SigmaDB([string]$database) {
        $this.database = $database
        $this.Open($this.database)
    }

    Open([string]$database) {
        $this.database = $database
        Open-SQLiteConnection -DataSource $this.database

        $tables = $this.Query("SELECT name FROM sqlite_master WHERE type='table';")

        # create tables if they don't exist
        if ($tables.count -eq 0) {
            # table 'rule'
            $create = ' CREATE TABLE "rule" (
                            "id"            TEXT NOT NULL UNIQUE,
                            "title"         TEXT,
                            "file_name"     TEXT,
                            "creation_date" TEXT,
                            "modified_date" TEXT,
                            "file_hash"     TEXT,
                            "is_eql"        INTEGER NOT NULL DEFAULT 0,
                            "is_custom"     INTEGER NOT NULL DEFAULT 0,
                            "is_enabled"    INTEGER NOT NULL DEFAULT 1,
                            "ignore_hash"   TEXT,
                            "install_date"  TEXT NOT NULL,
                            "update_date"   TEXT NOT NULL,
                            CONSTRAINT "rule_pk" PRIMARY KEY("id")
                        );'
            $this.Update($create)

            # table 'exception'
            $create = ' CREATE TABLE "exception" (
                            "id"                INTEGER NOT NULL UNIQUE,
                            "operator"          TEXT NOT NULL,
                            "search_identifier" TEXT NOT NULL,
                            "filter"            TEXT NOT NULL,
                            "rule_id"           TEXT NOT NULL,
                            CONSTRAINT "exception_pk" PRIMARY KEY("id" AUTOINCREMENT),
                            FOREIGN KEY("rule_id") REFERENCES "rule"("id") ON DELETE CASCADE
                        );'
            $this.Update($create)
        }
    }

    Open() {
        $this.Open($this.database)
    }

    [array] Query([string]$query, [hashtable]$parameters) {
        $answer = Invoke-SqlQuery -Query $query -Parameters $parameters -ErrorAction Stop
        if ($null -eq $answer) {
            $result = @()
        }
        elseif ($answer.Count -eq 1) {
            $result = @($answer)
        }
        else {
            $result = $answer
        }
        return $result
    }

    [array] Query([string]$query) {
        return $this.Query($query, $null)
    }

    Update([string]$query, [hashtable]$parameters) {
        Invoke-SqlUpdate -Query $query -Parameters $parameters -ErrorAction Stop | Out-Null
    }

    Update([string]$query) {
        $this.Update($query, $null)
    }

    [bool] Test() {
        return Test-SqlConnection
    }

    Close() {
        Close-SqlConnection
    }
}