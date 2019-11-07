import java.awt.dnd.*;
import java.awt.datatransfer.*;
import java.util.*;
import java.io.File;
import java.io.IOException;

public class MLDropTarget extends DropTarget
{
    /**
	 * Modified DropTarget to be used for drag & drop in MATLAB UI control.
	 */
	private static final long serialVersionUID = 1L;
    private int droptype;
	private Transferable t;
    private String[] transferData;
    
    public static final int DROPERROR = 0;
    public static final int DROPTEXTTYPE = 1;
    public static final int DROPFILETYPE = 2;
    
    @SuppressWarnings("unchecked")
    @Override
	public synchronized void drop(DropTargetDropEvent evt) {
    	
    	// Make sure drop is accepted
    	evt.acceptDrop(DnDConstants.ACTION_COPY_OR_MOVE);
    	
    	// Set droptype to zero
    	droptype = DROPERROR;        
        
        // Get transferable and analyze
        t = evt.getTransferable();
        
        try {
            if (t.isDataFlavorSupported(DataFlavor.javaFileListFlavor)) {
            	// Interpret as list of files
            	List<File> fileList = (ArrayList<File>) t.getTransferData(DataFlavor.javaFileListFlavor);
            	transferData = new String[fileList.size()];
            	for (int i = 0; i < fileList.size(); i++) 
            		transferData[i] = fileList.get(i).getAbsolutePath();
            	droptype = DROPFILETYPE;
            } 
            else if (t.isDataFlavorSupported(DataFlavor.stringFlavor)) {
            	// Interpret as string            	
            	transferData[0] = (String) t.getTransferData(DataFlavor.stringFlavor);
    			droptype = DROPTEXTTYPE;
            }
            	
        } catch (UnsupportedFlavorException e) {
        	droptype = DROPERROR;
        	super.drop(evt);        	
            return;
        } catch (IOException e) {
        	droptype = DROPERROR;
        	super.drop(evt);
            return;
        }
        
    	// Call built-in drop method (fire MATLAB Callback)       
        super.drop(evt);
    }
    
	public int getDropType() {
		return droptype;
	}	
	public Transferable getTransferable() {
        return t;
    }
    public String[] getTransferData() {
        return transferData;
    }
}