// SPDX-FileCopyrightText: 2024 Kapdap <kapdap@pm.me>
//
// SPDX-License-Identifier: MIT
/*  CONSCRIPT Auto Splitter
 *  https://github.com/kapdap/conscript-autosplitter
 *
 *  Copyright 2024 Kapdap <kapdap@pm.me>
 *
 *  Use of this source code is governed by an MIT-style
 *  license that can be found in the LICENSE file or at
 *  https://opensource.org/licenses/MIT.
 */

// Steam v1.0.0.2
state("CONSCRIPT") {
	int RoomId : "CONSCRIPT.exe", 0x1F6D590;
}

// GOG v1.0.0.0
state("CONSCRIPT", "v1.0.0.0 (G)") {
	int RoomId : "CONSCRIPT.exe", 0xDBD0B8;
}

init
{
    // Based on GameMaker room name scanner by ero
    Func<IntPtr, IntPtr> onFound = addr => addr + 0x4 + game.ReadValue<int>(addr);

    var exe = modules.First();
    var scn = new SignatureScanner(game, exe.BaseAddress, exe.ModuleMemorySize);

    if (exe.ModuleMemorySize == 0xE85000)
        version = "v1.0.0.0 (G)";

    var roomArrayTrg = new SigScanTarget(5, "74 0C 48 8B 05 ???????? 48 8B 04 D0");
    var roomArrLenTrg = new SigScanTarget(3, "48 3B 15 ???????? 73 ?? 48 8B 0D");

    var arr = game.ReadPointer(onFound(scn.Scan(roomArrayTrg)));
    var len = game.ReadValue<int>(onFound(scn.Scan(roomArrLenTrg)));
    
    vars.RoomNames = new string[len];

    if (len == 0)
        throw new InvalidOperationException(); 

    for (int i = 0; i < len; i++)
    {
        var name = game.ReadString(game.ReadPointer(arr + 0x8 * i), ReadStringType.UTF8, 64);
        vars.RoomNames[i] = name;
    }
}

start
{
    return vars.RoomNames[old.RoomId] == "rm_loading_assets" &&
           vars.RoomNames[current.RoomId] == "rm_tr_spawn";
}

update
{
    current.RoomName = vars.RoomNames[current.RoomId];
}