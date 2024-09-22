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

// Steam v1.0.1.2
state("CONSCRIPT", "v1.0.1.2 (S)") {
    int RoomId : "CONSCRIPT.exe", 0x1FB2750;
    double RESULTS_ACTIVE : "CONSCRIPT.exe", 0x21C5130, 0xB0, 0x320;
    long currentEnding : "CONSCRIPT.exe", 0x21C5130, 0xB0, 0x260;
}

// GOG v1.0.1.2
state("CONSCRIPT", "v1.0.1.2 (G)") {
    int RoomId : "CONSCRIPT.exe", 0x1B69538, 0x0, 0x18, 0x110;
    double RESULTS_ACTIVE : "CONSCRIPT.exe", 0x1B5A1C8, 0x30, 0x900, 0x50;
    long currentEnding : "CONSCRIPT.exe", 0x1B5A1C8, 0x30, 0x540, 0x40;
}

// TODO: Epic Games release
/*state("CONSCRIPT", "v1.0.0.0 (Epic)") {
    int RoomId : "CONSCRIPT.exe", 0xDBD0B8;
    double RESULTS_ACTIVE : "CONSCRIPT.exe", 0xBAD3F0, 0x30, 0x940, 0x40;
}*/

init
{
    // Based on GameMaker room name scanner by ero
    Func<IntPtr, IntPtr> onFound = addr => addr + 0x4 + game.ReadValue<int>(addr);

    var exe = modules.First();
    var scn = new SignatureScanner(game, exe.BaseAddress, exe.ModuleMemorySize);

    if (exe.ModuleMemorySize == 0x2379000)
        version = "v1.0.1.2 (S)";
    else if (exe.ModuleMemorySize == 0x1CCD000)
        version = "v1.0.1.2 (G)";

    var roomArrayTrg = new SigScanTarget(5, "74 0C 48 8B 05 ???????? 48 8B 04 D0");
    var roomArrLenTrg = new SigScanTarget(3, "48 3B 15 ???????? 73 ?? 48 8B 0D");

    var arr = game.ReadPointer(onFound(scn.Scan(roomArrayTrg)));
    var len = game.ReadValue<int>(onFound(scn.Scan(roomArrLenTrg)));

    if (len == 0)
        throw new InvalidOperationException("Unable to read room array length.");

    vars.RoomNames = new string[len];

    for (int i = 0; i < len; i++)
    {
        var name = game.ReadString(game.ReadPointer(arr + 0x8 * i), ReadStringType.UTF8, 64);
        vars.RoomNames[i] = name;
    }
}

start
{
    return vars.RoomNames[current.RoomId] == "rm_tr_spawn" && 
           current.RESULTS_ACTIVE == 1;
}

split
{
    // Splits after going to bed at the end of the flashbacks
    if (vars.RoomNames[old.RoomId] == "rm_cs_bedroom" &&
        vars.RoomNames[current.RoomId] == "rm_chapter_end")
        return true;
 
    // Splits after leaving in the truck at the end of chapter 5 flashback
    if (vars.RoomNames[old.RoomId] == "rm_cs_passage" &&
        vars.RoomNames[current.RoomId] == "rm_text" &&
        current.currentEnding != 6) // Don't split at the end of the secret ending
        return true;
 
    // End game split
    if (vars.RoomNames[old.RoomId] == "rm_ending_title" &&
        vars.RoomNames[current.RoomId] == "rm_credits")
        return true;
}

update
{
    current.RoomName = vars.RoomNames[current.RoomId];
}

isLoading
{
    return current.RESULTS_ACTIVE == 0;
}