# bashmenu.sh
```bash
source <(curl -sL bashmenu.sh)
```

## Description

`bashmenu.sh` is a script offering single and multi-selection menu functionalities in bash. It is designed to be sourced into other scripts, not executed directly.

The script provides two main functions: `singleselect` and `multiselect`, each requiring specific positional arguments:

- **Display Legend Flag** (string): `"true"` to display navigation instructions, any other value to hide them.
- **Result Variable Name** (string): The name of the variable where the result will be stored (as an array).
- **Options** (array): An array of strings representing the menu options.
- **Default Selection**:
  - For `multiselect`: An array of booleans (`true`/`false`) indicating preselected options.
  - For `singleselect`: An integer representing the index of the default selected option.

## Usage

### Navigation Controls

- `↓` (Down Arrow): Move cursor down
- `↑` (Up Arrow): Move cursor up
- `⎵` (Space): Toggle selection (for multiselect) / Make selection (for singleselect)
- `⏎` (Enter): Confirm selection

## Examples

```bash
# Source the script
source <(curl -sL bashmenu.sh)

# Define options
my_options=("Option 1" "Option 2" "Option 3")

# Using multiselect
preselection=("true" "false" "false")
multiselect "true" result my_options preselection

# Using singleselect
singleselect "true" result my_options 0  # 0 is the index of the default selected option

# Display the result
idx=0
for option in "${my_options[@]}"; do
    echo -e "$option\t=> ${result[idx]}"
    ((idx++))
done
