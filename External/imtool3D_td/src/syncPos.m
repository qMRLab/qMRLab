function syncPos(RECT1,RECT2,RECT3,ref)
switch ref
    case 1
        pos2 = RECT2.getPosition; pos1 = RECT1.getPosition; pos2([2 4]) = pos1([1 3]); RECT2.newPosition(pos2,1);
        pos3 = RECT3.getPosition; pos1 = RECT1.getPosition; pos3([2 4]) = pos1([2 4]); RECT3.newPosition(pos3,1);
    case 2
        pos2 = RECT2.getPosition; pos1 = RECT1.getPosition; pos1([1 3]) = pos2([2 4]); RECT1.newPosition(pos1,1);
        pos3 = RECT3.getPosition; pos2 = RECT2.getPosition; pos3([1 3]) = pos2([1 3]); RECT3.newPosition(pos3,1);
    case 3
        pos3 = RECT3.getPosition; pos1 = RECT1.getPosition; pos1([2 4]) = pos3([2 4]); RECT1.newPosition(pos1,1);
        pos3 = RECT3.getPosition; pos2 = RECT2.getPosition; pos2([1 3]) = pos3([1 3]); RECT2.newPosition(pos2,1);
end
end
