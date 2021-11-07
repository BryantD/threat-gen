#!/bin/sh

#### Author:	Abbi @ Earthen Ring (US)
####		strand.osric@gmail.com
#### Version:	1.0
#			1.0	Initial public release

ACTOR=$1

sed "
s/Your \(.*\) drains \(.*\) \(.*\) from \(.*\). You gain \(.*\) \(.*\)./$ACTOR's \1 drains \2 \3 from \4. $ACTOR gains \5 \6./
s/You hit/$ACTOR hits/
s/You crit/$ACTOR crits/
s/You gain/$ACTOR gains/
s/Your \(.*\) hits/$ACTOR's \1 hits/
s/Your \(.*\) crits/$ACTOR's \1 hits/
s/You suffer/$ACTOR suffers/
s/You reflect/$ACTOR reflects/
s/Your \(.*\) heals/$ACTOR's \1 heals/
s/You perform/$ACTOR performs/
s/You miss/$ACTOR misses/
s/You are afflicted by/$ACTOR is afflicted by/
s/Your \(.*\) was dodged/$ACTOR's \1 was dodged/
s/Your \(.*\) is parried/$ACTOR's \1 was parried/
s/Your \(.*\) was resisted/$ACTOR's \1 was resisted/
s/You attack. \(.*\) dodges./$ACTOR attacks. \1 dodges./
s/You attack. \(.*\) parries./$ACTOR attacks. \1 parries./
s/You cast/$ACTOR casts/
s/\(.*\) attacks. You parry./\1 attacks. $ACTOR parries./
s/\(.*\) attacks. You dodge./\1 attacks. $ACTOR dodges./
s/Your \(.*\) missed/$ACTOR's \1 missed/
s/You interrupt/$ACTOR interrupts/
s/Your \(.*\) failed./$ACTOR's \1 failed./
s/You attack but/$ACTOR attacks but/
s/You die./$ACTOR dies./
s/Your \(.*\) is removed by/$ACTOR's \1 is removed by/
s/hits you for/hits $ACTOR for/
s/fades from you/fades from $ACTOR/
s/heals you/heals $ACTOR/
s/misses you/misses $ACTOR/
"
