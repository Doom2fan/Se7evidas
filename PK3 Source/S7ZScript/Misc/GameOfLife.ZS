/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class S7_GameOfLife_EventHandler : EventHandler {
    S7_GameOfLife gol;
    bool paused;
    bool activated;

    override void UiTick () {
        if (gol && !paused && (level.time % 2) == 0)
            gol.UpdateBoard ();
    }

    override void RenderOverlay (RenderEvent e) {
        if (gol)
            gol.DrawBoard ();
    }

    override void NetworkProcess (ConsoleEvent e) {
        Array<string> commandStrings; commandStrings.Clear ();
        e.Name.Split (commandStrings, ":");

        if (commandStrings.Size () < 1)
            return;
        if (!(commandStrings [0] ~== "S7_GameOfLife") || consoleplayer != e.Player)
            return;

        if (commandStrings.Size () == 1)
            commandStrings.Push ("Activate");

        if (commandStrings [1] ~== "Activate") {
            activated = !activated;

            if (activated) {
                if (gol)
                    gol.Destroy ();

                gol = new ('S7_GameOfLife');
                gol.InitializeBoard ();
                paused = true;

                RequireMouse = true;
                IsUiProcessor = true;
            } else if (!activated && gol) {
                if (gol)
                    gol.Destroy ();
                gol = null;

                RequireMouse = false;
                IsUiProcessor = false;
            }
        } else if (commandStrings [1] == "Pause")
            paused = !paused;
    }

    override bool UiProcess (UiEvent e) {
        Vector2 scales = (double (Screen.GetWidth ()) / gol.BoardWidth, double (Screen.GetHeight ()) / gol.BoardHeight);

        if (e.Type == UiEvent.Type_LButtonDown && activated && paused) {
            int cellX = int (double (e.MouseX) / scales.X);
            int cellY = int (double (e.MouseY) / scales.Y);
            int cellPos = (gol.BoardWidth * cellY + cellX);

            gol.board [cellPos] = !gol.board [cellPos];

            return true;
        } else if (e.Type == UiEvent.Type_KeyDown && activated) {
            if (e.KeyChar == UiEvent.Key_Return) {
                SendNetworkEvent ("S7_GameOfLife:Pause");

                return true;
            } else if (e.KeyChar == UiEvent.Key_Escape) {
                SendNetworkEvent ("S7_GameOfLife");

                return true;
            }
        }

        return false;
    }
}

// Plays Conway's Game of Life
class S7_GameOfLife {
    // The cell colors.
    const ColorDead = color (0xFF, 0xFF, 0xFF);
    const ColorLive = color (0x00, 0x00, 0x00);

    // The dimensions of the board in cells.
    const BoardWidth  = 64;
    const BoardHeight = 64;

    // Holds the current state of the board.
    Array<bool> board, newBoard;

    // True if cell rules can loop around edges.
    bool loopEdges;

    void InitializeBoard () {
        // Resize the boards
        board.Clear ();
        board.Resize (BoardWidth * BoardHeight);
        newBoard.Clear ();
        newBoard.Resize (BoardWidth * BoardHeight);

        for (int i = 0; i < BoardWidth * BoardHeight; i++) {
            board [i] = false;
            newBoard [i] = false;
        }

        loopEdges = false;
    }

    // Draws the board to the console.
    void DrawBoard () {
        Vector2 scales = (double (Screen.GetWidth ()) / BoardWidth, double (Screen.GetHeight ()) / BoardHeight);

        for (int x = 0; x < BoardWidth; x++)
        for (int y = 0; y < BoardHeight; y++) {
            let col = board [BoardWidth * y + x] ? ColorLive : ColorDead;

            double leftCoords = x * scales.X,
                    topCoords = Y * scales.Y;
            double  rightCoords = (x + 1.) * scales.X,
                   bottomCoords = (y + 1.) * scales.Y;

            Screen.Clear (
                int (leftCoords ), int (topCoords   ),
                int (rightCoords), int (bottomCoords),
                col
            );
        }
    }

    // Moves the board to the next state based on Conway's rules.
    void UpdateBoard () {
        for (int y = 0; y < BoardHeight; y++) {
            for (int x = 0; x < BoardWidth; x++) {
                int n = CountLiveNeighbors (x, y);
                bool c = board [BoardWidth * y + x];

                // A live cell dies unless it has exactly 2 or 3 live neighbors.
                // A dead cell remains dead unless it has exactly 3 live neighbors.
                newBoard [BoardWidth * y + x] = (c && (n == 2 || n == 3) || !c && n == 3);
            }
        }

        // Set the board to its new state.
        board.Clear ();
        board.Copy (newBoard);
    }

    // Returns the number of live neighbors around the cell at position (x,y).
    int CountLiveNeighbors (int x, int y) {
        // The number of live neighbors.
        int value = 0;

        // This nested loop enumerates the 9 cells in the specified cells neighborhood.
        for (int j = -1; j <= 1; j++) {
            // If loopEdges is set to false and y+j is off the board, continue.
            if (!loopEdges && y + j < 0 || y + j >= BoardHeight)
                continue;

            // Loop around the edges if y+j is off the board.
            int k = (y + j + BoardHeight) % BoardHeight;

            for (int i = -1; i <= 1; i++) {
                // If loopEdges is set to false and x+i is off the board, continue.
                if (!loopEdges && x + i < 0 || x + i >= BoardWidth) {
                    continue;
                }

                // Loop around the edges if x+i is off the board.
                int h = (x + i + BoardWidth) % BoardWidth;

                // Count the neighbor cell at (h,k) if it is alive.
                value += (board [BoardWidth * k + h] ? 1 : 0);
            }
        }

        // Subtract 1 if (x,y) is alive since we counted it as a neighbor.
        return value - (board [BoardWidth * y + x] ? 1 : 0);
    }
}