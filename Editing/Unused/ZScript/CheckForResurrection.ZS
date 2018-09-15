//-------------------------------------------------------------------------------------------
    //
    // CheckForResurrection / P_CheckForResurrection
    //
    //-------------------------------------------------------------------------------------------
    const S7_CppPort_SqrtHalf = 0.7071075439453125;
    bool CheckForResurrection (bool usevilestates) {
        static const double S7_CppPort_XSpeed [] = { 1, S7_CppPort_SqrtHalf, 0, -S7_CppPort_SqrtHalf, -1, -S7_CppPort_SqrtHalf,  0,  S7_CppPort_SqrtHalf };
        static const double S7_CppPort_YSpeed [] = { 0, S7_CppPort_SqrtHalf, 1,  S7_CppPort_SqrtHalf,  0, -S7_CppPort_SqrtHalf, -1, -S7_CppPort_SqrtHalf };

        if (movedir != DI_NODIR) {
            double absSpeed = abs (Speed);

            Vector2 viletry = Vec2Offset (
                absSpeed * S7_CppPort_XSpeed [movedir],
                absSpeed * S7_CppPort_YSpeed [movedir], true);

            BlockThingsIterator it = BlockThingsIterator.CreateFromPos (viletry.X, viletry.Y, pos.Z - 64, (pos.Z + Height) + 64, 32., false);
            while (it.Next ()) {
                Actor corpsehit = it.thing;
                State raisestate = corpsehit.GetRaiseState ();

                if (raisestate != NULL) {
                    // Use the current actor's radius instead of the Arch Vile's default.
                    double maxdist = corpsehit.default.radius + radius;

                    // Not actually touching
                    if (abs (corpsehit.pos.X - it.position.X) > maxdist ||
                        abs (corpsehit.pos.Y - it.position.Y) > maxdist)
                        continue;

                    // Let's check if there are floors in between the archvile and its target
                    if (corpsehit.CurSector.PortalGroup != CurSector.PortalGroup) {
                        // If in a different section of the map, only consider possible if a line of sight exists.
                        if (!CheckSight (corpsehit))
                            continue;
                    } else {
                        Sector vilesec = CurSector;
                        Sector corpsec = corpsehit.CurSector;

                        // We only need to test if at least one of the sectors has a 3D floor.
                        // NOTE: This can't be ported with GZDoom's current feature set
                        /*Sector testsec = vilesec->e->XFloor.ffloors.Size() ? vilesec :
                            (vilesec != corpsec && corpsec->e->XFloor.ffloors.Size()) ? corpsec : NULL;
                        if (testsec) {
                            double zdist1, zdist2;
                            if (P_Find3DFloor(testsec, corpsehit->Pos(), false, true, zdist1)
                                != P_Find3DFloor(testsec, Pos(), false, true, zdist2))
                            {
                                // Not on same floor
                                if (vilesec == corpsec || fabs(zdist1 - Z()) > Height)
                                    continue;
                            }
                        }*/
                    }

                    corpsehit.vel.X = corpsehit.vel.Y = 0;

                    // [RH] Check against real height and radius
                    // NOTE: This can't be ported, either
                    double oldheight = corpsehit.Height;
                    double oldradius = corpsehit.Radius;
                    //ActorFlags oldflags = corpsehit.flags;

                    corpsehit.bSolid = true;
                    corpsehit.Height = corpsehit.default.Height;
                    bool check = corpsehit.CheckPosition (corpsehit.pos);
                    //corpsehit.flags = oldflags;
                    corpsehit.Radius = oldradius;
                    corpsehit.Height = oldheight;
                    if (!check)
                        continue;

                    // Got one!
                    let temp = target;
                    target = corpsehit;
                    A_FaceTarget ();

                    if (bFriendly) {
                        // If this is a friendly Arch-Vile (which is turning the resurrected monster into its friend)
                        // and the Arch-Vile is currently targetting the resurrected monster the target must be cleared.
                        if (lastenemy == temp)
                            lastenemy = NULL;
                        if (lastenemy == corpsehit)
                            lastenemy = NULL;
                        if (temp == target)
                            temp = NULL;
                    }

                    target = temp;

                    // Make the state the monster enters customizable.
                    State healState = FindState ("Heal");
                    if (state != NULL)
                        SetState (healState);
                    else if (usevilestates) {
                        // For Dehacked compatibility this has to use the Arch Vile's
                        // heal state as a default if the actor doesn't define one itself.
                        let archvile = GetDefaultByType ("Archvile");
                        if (archvile != NULL)
                            SetState (archvile.FindState ("Heal"));
                    }

                    corpsehit.A_PlaySound("vile/raise", CHAN_Body, attenuation: ATTN_IDLE);
                    let info = corpsehit.default;

                    // (trans&TRANSLATIONTYPE_MASK) >> TRANSLATION_SHIFT
                    if (((corpsehit.Translation & (255<<16)) >> 16) == TRANSLATION_Blood)
                        corpsehit.Translation = info.Translation; // Clean up bloodcolor translation from crushed corpses

                    // NOTE: No idea how to port the if's condition
                    /*if (ib_compatflags & BCOMPATF_VILEGHOSTS) {
                        corpsehit->Height *= 4;
                        // [GZ] This was a commented-out feature, so let's make use of it,
                        // but only for ghost monsters so that they are visibly different.
                        if (corpsehit->Height == 0)
                        {
                            // Make raised corpses look ghostly
                            if (corpsehit->Alpha > 0.5)
                            {
                                corpsehit->Alpha /= 2;
                            }
                            // This will only work if the render style is changed as well.
                            if (corpsehit->RenderStyle == LegacyRenderStyles[STYLE_Normal])
                            {
                                corpsehit->RenderStyle = STYLE_Translucent;
                            }
                        }
                    } else*/ {
                        corpsehit.Height = info.Height;   // [RH] Use real mobj height
                        corpsehit.radius = info.radius;   // [RH] Use real radius
                    }

                    // NOTE: This function doesn't have a ZScript version
                    //corpsehit.Revive ();

                    // You are the Archvile's minion now, so hate what it hates
                    corpsehit.CopyFriendliness (self, false);
                    corpsehit.SetState (raisestate);

                    return true;
                }
            }
        }
        return false;
    }