clear all; close all


%% case 1
fprintf('\n\n\nCase 1\n')

surf(peaks)
axis vis3d
h = camlight('left');
a = get(gca);
set(gca,'view',[30,60])
b = get(gca);
b.junk = 'test';
[match, er1, er2] = comp_struct(a,b,1);
match
er1
list_struct(er1)
er2
list_struct(er2)

fprintf('\n\n\n\n\n');

if menu('Run next test?','Yes','No') - 1; error('Stop run'); end

%% case 2

clear all; close all
fprintf('\n\n\nCase 2\n')

% first struct
a(1).a = 1;
a(2).a = 2;
a(1).b.a = 'test';
a(2).b.a = 'test';
a(1).b.b = cellstr('a');
a(2).b.b = cellstr('a');
a(1).b.c = 1==1;
a(2).b.c = 1==1;
a(1).c = single([1 2 3]);
a(2).c = single([1 2 3]);
a(1).d(1).a = int8(2);
a(1).d(2).a = uint8(2);
a(1).d(3).a = int16(2);
a(1).d(4).a = uint16(2);
a(1).d(5).a = int32(2);
a(1).d(6).a = uint32(2);
a(1).d(7).a = int64(2);
a(1).d(8).a = uint64(2);
a(2).d(1).a = int8(2);
a(2).d(2).a = uint8(2);
a(2).d(3).a = int16(2);
a(2).d(4).a = uint16(2);
a(2).d(5).a = int32(2);
a(2).d(6).a = uint32(2);
a(2).d(7).a = int64(2);
a(2).d(8).a = uint64(2);
a(1).e = @(x)sin(x);
a(2).e = @(x)sin(x);
a(1).f = 1;
a(1).j = [1.1 2.2 3.3];
a(1).k = @(x)sin(x);



% second struct
b = a;
b(2).a = 1;
b(2).b.a = 'x';
b(2).b.b = cellstr('b');
b(2).b.c = 1==2;
b(2).c = single([1 2 5]);
b(2).d(1).a = int8(4);
b(2).d(2).a = uint8(54);
b(2).d(3).a = int16(5);
b(2).d(4).a = uint16(65);
b(2).d(5).a = int32(7);
b(2).d(6).a = uint32(7);
b(2).d(7).a = int64(7);
b(2).d(8).a = uint64(7);
b(2).e = @(x)tan(x);
b(1).f = 1+1e-8;
b(1).j = single(a(1).j);


% non-match
a(2).h = 1;
b(1).g = 1;
b(2).i.a = 'r';
b(3) = b(2);
b(4) = b(2);
x = .5; a(2).k = @(x)sin(x);
x = .25; b(2).k = @(x)sin(x);
a(1).l.a = 1;
b(1).l.c = 2;

a(1).o = 't';
b(1).o = 5;

% wrong order fields
a(1).m.a = 1; a(1).m.b = 1;
a(1).n.a = 1; a(1).n.b = 1;
b(1).n.b = 1; b(1).n.a = 1;
b(1).m.b = 1; b(1).m.a = 1;

[match, er1, er2] = comp_struct(a,b,1,0,1e-3);

match
er1
er2

if menu('Run next test?','Yes','No') - 1; error('Stop run'); end



%% case 3
clear all; close all
fprintf('\n\n\nCase 3\n')

a.a = 1; b.a = 1;
a.b = 2; b.b = 1;
a.c.a = 1; a.c.b = 2; b.c = 1;
a.d = cellstr('test')'; b.d = cellstr('test')'; 
a.e = cellstr('test')'; b.e = cellstr('a')'; 
a.f = 'tt'; b.f = 'tt';
a.g = 'tt'; b.g = 't';
a.h.a = 1; b.h.b = 1;
a.i.a = 1;
a.j.a = @sin; b.j.a = @sin;
a.j.b = @sin; b.j.b = @cos;
x = .1; a.j.c = @(x) sin(x); x = .5; b.j.c = @(x) sin(x); 
a(2) = a(1); b(2) = b(1); a(3) = a(1);


[match, er1, er2] = comp_struct(a,b);
match
list_struct(match)
er1
list_struct(er1)
er2
list_struct(er2)

if menu('Run next test?','Yes','No') - 1; error('Stop run'); end


%% case 4
clear all; close all
fprintf('\n\n\nCase 4\n')


str = char(97:122);

% build structure
for ii = 1:26
	stu1.(str(ii)) = rand(ceil(5*rand(1)),ceil(5*rand(1)));
end
stu2 = stu1;
for ii = 1:26
	if round(rand(1))
		if rand(1) > 0.3
			if round(rand)
				stu2.(str(ii)) = rand(size(stu2.(str(ii))));
			else
				stu2.(str(ii)) = stu2.(str(ii)) + 1e-8;
			end
		else
			stu2.(str(ii)) = rand(ceil(5*rand(1)),ceil(5*rand(1)));
		end
	end
end

[match, er1, er2] = comp_struct(stu1,stu2);
match
er1
list_struct(er1)
er2
list_struct(er2)
