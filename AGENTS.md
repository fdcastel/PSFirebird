# This shell is PowerShell 7.5

- use `pwsh` as shell
- Command separator is ';', not '&&'.



# This project code is for Windows PowerShell 7.5

- You don't need to keep backwards compatibility with Windows PowerShell 5.1.
- Keep one function per file, unless the functions are closely related.



## About strings

- Use single quotes for literal strings
- Use double quotes for interpolated strings  
- Always use `$()` wrapper for variable interpolation
- Use backtick (`` ` ``) for escaping in double-quoted strings
- Double quotes for escaping in single-quoted strings
- Never use backslash (`\`) as escape character
- Avoid double backslashes (`\\`) in paths. Use forward slashes (`/`) instead.
- Use Powershell here-strings for complex multi-line content
- Test string output to verify correct interpretation



# Verbose / debugging

- Verbose outputs are for debugging.  
- Include verbose messages that may help with future debugging. But just the minimum necessary for a useful debugging analysis. Do not to overdo it.
  - Always use the Write-VerboseMark function to produce verbose messages.
- Ensure all conditional and loop statements include a `Write-VerboseMark` call to output appropriate messages for debugging. This ensures better traceability of conditional logic during execution. 
  - Do not this for guard statements (`if` statements that ONLY throw an exception for a given condition)
  - Do not use `Write-Verbose` directly before a throw. The exception message should be clear enough without additional verbose output.
