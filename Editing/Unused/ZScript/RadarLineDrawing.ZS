            // This is bork. idk why. also scaling breaks it for some retarded reason
            let linesIterator = BlockLinesIterator.Create (CPlayer.mo, RADAR_MAXDIST);
            while (linesIterator.Next ()) {
                let curLine = linesIterator.CurLine;

                // Coords
                Vector2 worldPosV0 = (pPawnXYPos.xy - curLine.v1.p) / RADAR_SCALE, screenPosV0;
                Vector2 worldPosV1 = (pPawnXYPos.xy - curLine.v2.p) / RADAR_SCALE, screenPosV1;

                bool intersected;
                [intersected, worldPosV0, worldPosV1] = LineClipCircle (pPawnXYPos.xy - curLine.v1.p, pPawnXYPos.xy - curLine.v2.p, pPawnXYPos.xy, RADAR_RADIUS * RADAR_SCALE);

                if ((worldPosV0 - pPawnXYPos.xy).Length () ~== RADAR_RADIUS * RADAR_SCALE && 
                    (worldPosV1 - pPawnXYPos.xy).Length () ~== RADAR_RADIUS * RADAR_SCALE)
                    continue;

                worldPosV0 /= RADAR_SCALE;
                worldPosV1 /= RADAR_SCALE;

                Vector2 interPosV0 = (worldPosV0.x * angleSin + worldPosV0.y * angleCos,
                                      worldPosV0.x * angleCos - worldPosV0.y * angleSin) + radarOffs;
                Vector2 interPosV1 = (worldPosV1.x * angleSin + worldPosV1.y * angleCos,
                                      worldPosV1.x * angleCos - worldPosV1.y * angleSin) + radarOffs;

                //[intersected, screenPosV0, screenPosV1] = LineClipCircle (interPosV0, interPosV1, radarOffs, RADAR_RADIUS);

                if (screenPosV0 == screenPosV1) // Just in case
                    continue;

                DrawLine (interPosV0, interPosV1, Color (256, 256, 256, 0), DI_SCREEN_RIGHT_TOP);
            }