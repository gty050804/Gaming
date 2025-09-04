global count
global matrix

matrix=zeros(10,10);
count=0;
mouse_track();

function mouse_track()

   figure;
   grid on
   axis square
   axis equal
   axis([0,11,0,11])
   set(gca,'XTick',(0:11));
   set(gca,'YTick',(0:11));
   box on
   set(gcf,'WindowButtonDownFcn',@ButtonDownFcn);
end









% figure
% grid on
% axis square
% axis equal
% axis([-5 5 -5 5])
% set(gca,'XTick',(-5:1:5));
% set(gca,'YTick',(-5:1:5));
% box on
% set(gcf,'WindowButtonDownFcn',@ButtonDownFcn);

function ButtonDownFcn(~,~)
   global count
   global matrix
   hold on
   pt=get(gca,'CurrentPoint');
   x=round(pt(1,1));
   y=round(pt(1,2));
   if (x<11&&x>0)&&(y<11&&y>0)&&(matrix(x,y)==0)
       if mod(count,2)==0
           scatter(x,y,300,'ok','filled');
       else
           scatter(x,y,300,'ok');
       end

       matrix(x,y)=1;
       count=count+1;
   end



   % scatter(x,y,300,'o','filled');
   % fprintf('x=%d,y=%d\n',x,y);
end
