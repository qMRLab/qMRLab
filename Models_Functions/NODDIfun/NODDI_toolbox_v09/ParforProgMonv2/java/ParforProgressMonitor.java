import javax.swing.*;
import java.io.*;
import java.net.*;
import java.util.concurrent.atomic.AtomicBoolean;

// Copyright 2009 The MathWorks, Inc.

public class ParforProgressMonitor {

    /**
     * Create a "server" progress monitor - this runs on the desktop client and
     * pops up the progress monitor UI.
     */
    public static ProgServer createServer( String s, int N, int progressStepSize, int width, int height )
        throws IOException {
        ProgServer ret = new ProgServer( s, N, progressStepSize, width, height );
        ret.start();
        return ret;
    }

    /**
     * Create a "worker" progress monitor - runs on the remote lab and sends updates
     */
    public static ProgWorker createWorker( String host, int port )
        throws IOException {
        return new ProgWorker( host, port );
    }

    /**
     * Common interface exposed by both objects
     */
    public interface ProgThing {
        public void increment();
        public void done();
    }

    /**
     * The worker-side object. Simply connects to the server to indicate that a
     * quantum of progress has been made. This is a very basic implementation -
     * a more sophisticated implementation would use a persistent connection,
     * and a SocketChannel on the client with a thread doing a select loop and
     * accepting connections etc.
     */
    private static class ProgWorker implements ProgThing {
        private int fPort;
        private String fHost;
        private ProgWorker( String host, int port ) {
            fHost = host;
            fPort = port;
        }

        /**
         * Connect and disconnect immediately to indicate progress
         */
        public void increment() {
            try {
                Socket s = new Socket( fHost, fPort );
                s.close();
            } catch( Exception e ) {
                e.printStackTrace();
            }
        }

        /**
         * Nothing for us to do here
         */
        public void done() {
        }
    }

    /**
     * The client-side object which pops up a window with a
     * JProgressBar. Accepts connections from the workers, and then disconnects
     * them immediately. Beware, the connection backlog of the ServerSocket
     * might be insufficient.
     */
    private static class ProgServer implements Runnable, ProgThing {
        private JFrame fFrame;
        private JProgressBar fBar;
        private ServerSocket fSocket;
        private int fValue, fN, fStep;
        private String title;
        private Thread fThread;
        private AtomicBoolean fKeepGoing;

        private ProgServer( String s, int N, int progressStepSize, int width, int height ) throws IOException {
            // The UI
            fFrame = new JFrame( s );
            fBar   = new JProgressBar( 0, N );
            fFrame.getContentPane().add( fBar );
            fFrame.pack();
			fFrame.setSize(width,height);
            fFrame.setLocationRelativeTo( null );
            fFrame.setVisible( true );

            // How far we are through - requires synchronized access
            fValue = 0;
			fN = N;
			fStep = progressStepSize;
			title = s;

            // Get an anonymous port
            fSocket = new ServerSocket( 0 );
            // Set SO_TIMEOUT so that we don't block forever
            fSocket.setSoTimeout( 100 );

            // Our background thread
            fThread = new Thread( this );
            fThread.setDaemon( true );

            // Used to indicate to fThread when it's time to go
            fKeepGoing = new AtomicBoolean( true );
        }

        /**
         * Don't start the Thread in the constructor
         */
        public void start() { fThread.start(); }

        /**
         * Loop over accepting connections and updating
         */
        public void run() {
            while( fKeepGoing.get() ) {
                try {
                    acceptAndIncrement();
                } catch( Exception e ) {
                    if( fKeepGoing.get() ) {
                        e.printStackTrace();
                    }
                }
            }
        }

        /**
         * If there's a connection - accept and then disconnect; increment our count.
         */
        private void acceptAndIncrement() throws IOException {
            Socket worker;
            try {
                worker = fSocket.accept();
            } catch( SocketTimeoutException timeout ) {
                // don't care about timeouts
                return;
            }
            worker.close();
            increment();
        }


        /**
         * On the EDT, update the progress bar
         */
        private void updateBar( final int newVal ) {
            SwingUtilities.invokeLater( new Runnable() {
                    public void run() {
                        fBar.setValue( fStep*newVal );
                        double percentage = 100.0*fStep*newVal/fN;
                        fFrame.setTitle(title + (int)percentage + "% completed.");
                        if ( newVal == fBar.getMaximum() ) {
                            done();
                        }
                    }
                } );
        }

        /**
         * M-code needs to know which port we got
         */
        public int getPort() {
            return ((InetSocketAddress)fSocket.getLocalSocketAddress()).getPort();
        }

        /**
         * Provide public access to this for pool-close PARFORs
         */
        public synchronized void increment() {
            fValue++;
            updateBar( fValue );
        }

        /**
         * Shut it all down
         */
        public void done() {
            fKeepGoing.set( false );
            try {
                fSocket.close();
            } catch( Exception e ) {
                e.printStackTrace();
            }
            fFrame.dispose();
        }
    }

    /** This class isn't useful - use the static methods */
    private ParforProgressMonitor() {}
}