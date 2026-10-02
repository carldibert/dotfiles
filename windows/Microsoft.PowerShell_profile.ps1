# PowerShell 7 profile (open it with: notepad $PROFILE)
# Prompt: the same wholespace-frappe prompt as zsh, drawn by oh-my-posh
oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\wholespace-frappe.omp.json" | Invoke-Expression

# Grey inline suggestions from history, like zsh-autosuggestions
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView
