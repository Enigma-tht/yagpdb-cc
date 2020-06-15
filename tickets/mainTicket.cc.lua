{{/*
    This command is to go into your "Opening message in new tickets" box.
    (Control panel -> Tools & Utilities -> Ticket Sytem)

    Dont change anything!
*/}}

{{/* ACTUAL CODE! DONT TOUCH */}}
{{/* START */}}
{{$tn := reFind `\d+` .Channel.Name}}
{{editChannelName .Channel.ID (print "ticket-" $tn)}}
{{$setup := sdict (dbGet 0 "ticket_cfg").Value}}
{{$CloseEmoji := $setup.CloseEmoji}}
{{$SolveEmoji := $setup.SolveEmoji}}
{{$AdminOnlyEmoji := $setup.AdminOnlyEmoji}}
{{$ConfirmCloseEmoji := $setup.ConfirmCloseEmoji}}
{{$CancelCloseEmoji := $setup.CancelCloseEmoji}}
{{$ModeratorRoleID := toInt $setup.MentionRoleID}}
{{$SchedueledCCID := toInt $setup.SchedueledCCID}}
{{$masterChannel := toInt $setup.masterTicketChannelID}}
{{$displayMSGID := toInt $setup.displayMSGID}}
{{$Delay := toInt $setup.Delay}}
{{$TO := $setup.ticketOpen}}
{{$TS := $setup.ticketClose}}
{{$TC := $setup.ticketSolving}}
{{$time :=  currentTime}}
{{$content := print "Welcome, " .User.Mention "\nNew ticket opened, <@&" $ModeratorRoleID "> !!"}}
{{$descr := print "Soon a  <@&" $ModeratorRoleID "> will talk to you! For now, you can start telling us what's the issue, so that we can help you faster! :)\nIn case you dont need help anymore, or you want to close this ticket, click on the " $CloseEmoji " and then on the " $ConfirmCloseEmoji " that will show up!"}}
{{$embed := cembed "color" 8190976 "description" $descr "timestamp" $time}}
{{$id := sendMessageNoEscapeRetID nil (complexMessage "content" $content "embed" $embed)}}
{{addMessageReactions nil $id $CloseEmoji $SolveEmoji $AdminOnlyEmoji}}
{{$realDelay := mult $Delay 3600}}
{{$AoD := 1}}
{{if gt $Delay 3}} {{$AoD = 2}} {{end}}
{{if eq $AoD 1}}
    {{scheduleUniqueCC $SchedueledCCID nil $realDelay $tn (sdict "alert" 2)}}
    {{dbSet (toInt $tn) "ticket" (sdict "AoD" $AoD "Delay" (str $Delay) "pos" 1 "ticketID" $tn "userID" (str .User.ID) "mainMsgID" (str $id) "ticketCounter" (str 0) "duration" ($time.Add (toDuration (print $Delay "h30m"))) "ctime" $time "alert" 2 "creator" (userArg .User.ID))}}
{{else}}
    {{$3HoursAlert := sub $realDelay 10800}}
    {{scheduleUniqueCC $SchedueledCCID nil $3HoursAlert $tn (sdict "alert" 1)}}
    {{dbSet (toInt $tn) "ticket" (sdict "AoD" $AoD "Delay" (str $Delay) "pos" 1 "ticketID" $tn "userID" (str .User.ID) "mainMsgID" (str $id) "ticketCounter" (str 0) "duration" ($time.Add (toDuration (print $Delay "h"))) "ctime" $time "alert" 1 "creator" (userArg .User.ID))}}
{{end}}
{{with (dbGet 0 "ticketDisplay").Value}}
    {{$map := sdict .}}
    {{if lt (len .) 50}}
        {{$map.Set $tn $TO}}
    {{else}}
        {{$pos := 0}}
        {{range $k, $v := .}}
            {{- if eq $pos 0}} {{$pos = toInt $k}} {{end -}}
            {{- if lt (toInt $k) $pos}} {{$pos = toInt $k}} {{end -}}
        {{end}}
        {{$map.Del $pos}}
        {{$map.Set $tn $TO}}
    {{end}}
    {{dbSet 0 "ticketDisplay" $map}}
{{else}}
    {{dbSet 0 "ticketDisplay" (sdict $tn $TO)}}
{{end}}
{{$arr := cslice}}
{{with (dbGet 0 "ticketDisplay").Value}}
    {{$map := sdict .}}
    {{range $k, $v := $map}} {{- $arr = $arr.Append (cslice $k $v) -}} {{end}}
    {{$len := len $arr}}
    {{range seq 0 $len}}
        {{- $min := . -}}
        {{- range seq (add . 1) $len -}}
            {{- if lt (index $arr $min 1) (index $arr . 1) }} {{ $min = . }} {{ end -}}
        {{- end -}}
        {{- if ne $min . -}}
            {{- $ := index $arr . -}}
            {{- $arr.Set . (index $arr $min) -}}
            {{- $arr.Set $min $ -}}
        {{- end -}}
    {{end}}
{{end}}
{{$list := cslice (len $TO) (len $TC) (len $TS)}}
{{$biggest := 0}}
{{$desc := printf "%s - %-10s\n" "**TicketID**" "**Status**"}}
{{range $arr}} {{- $desc = print $desc (printf (print "`#%06d` - `%-" (index . 1 | len) "s`\n") (index . 0 | toInt) (index . 1)) -}} {{end}}
{{editMessage $masterChannel $displayMSGID (cembed "title" "Tickets Display" "color" (randInt 16777216) "description" $desc)}}
