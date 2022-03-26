alias pa="php artisan"
alias sa="sail artisan"
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'
alias tests='nocorrect sail test'
alias fresh='sa migrate:fresh'
alias fs='fresh --seed'
